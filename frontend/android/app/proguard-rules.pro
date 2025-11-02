# Flutter and Dart specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase and Google Services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Google ML Kit Text Recognition - Keep all classes
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }

# Google ML Kit Commons
-keep class com.google.mlkit.common.** { *; }
-keep class com.google.mlkit.vision.common.** { *; }

# Camera plugin
-keep class io.flutter.plugins.camera.** { *; }

# Image picker plugin
-keep class io.flutter.plugins.imagepicker.** { *; }

# File picker plugin
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Shared preferences plugin
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Permission handler plugin
-keep class com.baseflow.permissionhandler.** { *; }

# HTTP plugin
-keep class io.flutter.plugins.flutter_plugin_android_lifecycle.** { *; }

# Prevent obfuscation of native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable classes
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepnames class * implements java.io.Serializable

# Gson specific classes
-keep class com.google.gson.** { *; }

# Remove debug logs in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
}