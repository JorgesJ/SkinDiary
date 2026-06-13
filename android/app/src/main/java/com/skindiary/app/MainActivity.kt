package com.skindiary.app

import android.net.Uri
import android.os.Bundle
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import androidx.activity.OnBackPressedCallback
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.webkit.WebViewAssetLoader
import androidx.webkit.WebViewClientCompat
import com.skindiary.app.databinding.ActivityMainBinding

/**
 * Actividad principal: aloja un WebView que sirve la app web de SkinDiary
 * desde los assets locales mediante WebViewAssetLoader.
 *
 * Se usa el host virtual https://appassets.androidplatform.net/ para que la
 * web se ejecute en un origen seguro estable, necesario para que funcionen
 * correctamente localStorage y demás APIs web.
 */
class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding

    // Callback para devolver el/los archivo(s) elegidos al <input type="file">.
    private var fileChooserCallback: ValueCallback<Array<Uri>>? = null

    // Lanzador del selector de archivos del sistema (galería / explorador).
    private val fileChooserLauncher =
        registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
            val uris = WebChromeClient.FileChooserParams.parseResult(result.resultCode, result.data)
            fileChooserCallback?.onReceiveValue(uris ?: emptyArray())
            fileChooserCallback = null
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        configureWebView()
        setupBackNavigation()

        if (savedInstanceState == null) {
            binding.webView.loadUrl(START_URL)
        }
    }

    private fun configureWebView() {
        val webView: WebView = binding.webView

        // Sirve los assets locales bajo /assets/ del host virtual seguro.
        val assetLoader = WebViewAssetLoader.Builder()
            .addPathHandler("/assets/", WebViewAssetLoader.AssetsPathHandler(this))
            .build()

        webView.webViewClient = object : WebViewClientCompat() {
            override fun shouldInterceptRequest(
                view: WebView,
                request: WebResourceRequest
            ): WebResourceResponse? {
                return assetLoader.shouldInterceptRequest(request.url)
            }
        }

        // Soporte para <input type="file"> (elegir foto de la galería).
        webView.webChromeClient = object : WebChromeClient() {
            override fun onShowFileChooser(
                webView: WebView,
                filePathCallback: ValueCallback<Array<Uri>>,
                fileChooserParams: FileChooserParams
            ): Boolean {
                // Cancela cualquier petición pendiente previa.
                fileChooserCallback?.onReceiveValue(null)
                fileChooserCallback = filePathCallback
                return try {
                    fileChooserLauncher.launch(fileChooserParams.createIntent())
                    true
                } catch (e: Exception) {
                    fileChooserCallback = null
                    false
                }
            }
        }

        webView.settings.apply {
            javaScriptEnabled = true          // la app usa JS
            domStorageEnabled = true          // necesario para localStorage
            allowFileAccess = false           // servimos vía asset loader, no file://
            allowContentAccess = false
            mediaPlaybackRequiresUserGesture = true
        }
    }

    /** Hace que el botón "atrás" navegue por el historial del WebView. */
    private fun setupBackNavigation() {
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                if (binding.webView.canGoBack()) {
                    binding.webView.goBack()
                } else {
                    isEnabled = false
                    onBackPressedDispatcher.onBackPressed()
                }
            }
        })
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        binding.webView.saveState(outState)
    }

    override fun onRestoreInstanceState(savedInstanceState: Bundle) {
        super.onRestoreInstanceState(savedInstanceState)
        binding.webView.restoreState(savedInstanceState)
    }

    companion object {
        private const val START_URL =
            "https://appassets.androidplatform.net/assets/web/index.html"
    }
}
