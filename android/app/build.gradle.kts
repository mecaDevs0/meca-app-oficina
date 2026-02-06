plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "br.com.megaleios.meca_oficina"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "br.com.megaleios.meca_oficina"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("config") {
            keyAlias = "megaleios"
            keyPassword = "@@MegaleiosCkua36@@"
            storeFile = file("megaleios.jks")
            storePassword = "@@MegaleiosCkua36@@"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("config")
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            signingConfig = signingConfigs.getByName("config")
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = false
        }
    }

    bundle {
        language {
            enableSplit = false
        }
        density {
            enableSplit = false
        }
        abi {
            enableSplit = false
        }
    }
    
    // Força remoção de permissões READ_MEDIA do manifest final
    androidComponents {
        onVariants { variant ->
            variant.packaging.resources.excludes.add("META-INF/com/android/build/gradle/app-metadata.properties")
        }
    }
    
    splits {
        abi {
            isEnable = false
        }
    }
}

flutter {
    source = "../.."
}


dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
