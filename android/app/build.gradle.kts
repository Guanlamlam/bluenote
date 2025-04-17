plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.bluenote"

    // Set compileSdk version explicitly (latest stable version)
    compileSdk = 35  // Set the latest compile SDK version

    // Set NDK version if necessary (Flutter SDK provides a default, but you can specify a version)
    ndkVersion = "27.0.12077973"  // Optional: Only if your dependencies need a specific version

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.bluenote"

        // Set the minSdkVersion to 23 to support Firebase Auth and other Firebase dependencies
        minSdk = 23  // Set the minSdkVersion to at least 23 as required by firebase_auth

        // Set targetSdkVersion (latest stable version)
        targetSdk = 33  // Set targetSdkVersion to the latest stable version

        // Automatically set by Flutter (ensure it's in sync)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")  // Optional: Change this when you're ready for release
        }
    }
}

flutter {
    source = "../.."  // Ensure the Flutter SDK path is correct
}
