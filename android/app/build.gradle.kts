plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
}

android {
    namespace = "com.skindiary.app"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.skindiary.app"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        viewBinding = true
    }
}

/**
 * Copia la app web (HTML/CSS/JS) desde la raíz del repositorio a los assets
 * de la app Android, para que el WebView la sirva localmente.
 * Así existe una única fuente de verdad: la web vive en la raíz del repo.
 */
val webRoot = rootProject.projectDir.parentFile // -> carpeta SkinDiary/
val copyWebAssets by tasks.registering(Copy::class) {
    description = "Copia los assets web de SkinDiary a los assets de la app."
    from(webRoot) {
        include("index.html")
        include("styles/**")
        include("js/**")
    }
    into(layout.projectDirectory.dir("src/main/assets/web"))
}

tasks.named("preBuild") {
    dependsOn(copyWebAssets)
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.appcompat)
    implementation(libs.androidx.activity)
    implementation(libs.androidx.webkit)
}
