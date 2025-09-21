plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // Needed for Firebase
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // Must come last
}

android {
    namespace = "com.example.frontend"
    compileSdk = 36   // ✅ Update this

    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.frontend"
        minSdk = flutter.minSdkVersion
        targetSdk = 36   // ✅ Update this
        versionCode = (project.findProperty("flutterVersionCode") as String).toInt()
        versionName = project.findProperty("flutterVersionName") as String
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}


flutter {
    source = "../.."
}
