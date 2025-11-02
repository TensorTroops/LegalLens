plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // For Firebase / MLKit
    id("dev.flutter.flutter-gradle-plugin") // Must come last
}

android {
    namespace = "com.example.frontend"
    compileSdk = 36 // Updated to support newer dependencies

    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    defaultConfig {
        applicationId = "com.tensortroops.legallens"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = (project.findProperty("flutterVersionCode") as String).toInt()
        versionName = project.findProperty("flutterVersionName") as String
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    buildTypes {
        getByName("debug") {
            isMinifyEnabled = false
        }
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    ndkVersion = flutter.ndkVersion
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
