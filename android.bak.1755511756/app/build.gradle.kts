plugins {
    id("com.android.application")
    id("kotlin-android")
    // Le plugin Flutter doit rester après Android & Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.front_flutter"

    // SDK/NDK
    compileSdk = 34
    ndkVersion = "27.0.12077973"

    // Java/Kotlin 17 (AGP 8.x)
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.front_flutter"
        minSdk = 23
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"

        // ✅ Forcer les ABI supportées (ton téléphone est arm64)
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }
    }

    // ✅ Générer des APK par ABI + un APK universel (pratique en debug)
    splits {
        abi {
            isEnable = true
            reset()
            include("arm64-v8a", "armeabi-v7a")
            isUniversalApk = true
        }
    }

    // ✅ Ne rien exclure dans les libs natives
    packaging {
        jniLibs {
            // S'assure qu'aucun exclude précédent ne reste actif
            excludes.clear()
            // Ne PAS ajouter d'excludes ici.
        }
    }

    buildTypes {
        release {
            // Signature debug pour simplifier
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
