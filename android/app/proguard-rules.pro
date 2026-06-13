# Reglas de ProGuard/R8 para SkinDiary.
# La app es un envoltorio WebView; no se exponen interfaces JS a Java,
# por lo que no se necesitan reglas especiales de momento.

# Mantener nombres de fuente para depuración de stack traces.
-keepattributes SourceFile,LineNumberTable
