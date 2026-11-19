# ─────────────────────────────────────────────
# Flutter
# ─────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# ─────────────────────────────────────────────
# Firebase / FCM
# ─────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ─────────────────────────────────────────────
# Supabase / OkHttp / Gson
# ─────────────────────────────────────────────
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# ─────────────────────────────────────────────
# Kotlin Coroutines
# ─────────────────────────────────────────────
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-dontwarn kotlinx.coroutines.**

# ─────────────────────────────────────────────
# DD Online app classes
# ─────────────────────────────────────────────
-keep class com.ddonline.app.** { *; }

# ─────────────────────────────────────────────
# Crash / stack trace окуу үчүн
# ─────────────────────────────────────────────
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile