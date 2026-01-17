# ProGuard 混淆規則

# 不混淆所有代碼
-dontshrink
-dontobfuscate
-dontoptimize

# 保留應用的主類
-keep public class com.fileserveapp.** { *; }

# 保留所有 native 方法
-keepclasseswithmembernames class * {
    native <methods>;
}

# 保留自定義應用異常
-keep public class * extends java.lang.Exception

# 保留 AndroidX
-keep class androidx.** { *; }
-keep interface androidx.** { *; }

# 保留系統類
-keep public class android.** { *; }
-keep interface android.** { *; }
