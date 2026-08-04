plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    id("com.google.firebase.firebase-perf")
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.risksphere.green"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }


    defaultConfig {
        applicationId = "com.risksphere.green"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["appAuthRedirectScheme"] =
            "com.risksphere.green"
    }

    signingConfigs {
        create("release") {
            storeFile = file("/Users/naveen/Documents/new-upload-key.jks")
            storePassword = "zerozilla"
            keyAlias = "upload"
            keyPassword = "zerozilla"
        }

        create("qa") {
            storeFile = file("/Users/naveen/Documents/new-upload-key.jks")
            storePassword = "zerozilla"
            keyAlias = "upload"
            keyPassword = "zerozilla"
        }

        getByName("debug") {
            storeFile = file("/Users/naveen/Documents/new-upload-key.jks")
            storePassword = "zerozilla"
            keyAlias = "upload"
            keyPassword = "zerozilla"
        }
    }

    buildTypes {

        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }

        create("qa") {
            initWith(getByName("debug"))
            isDebuggable = true
            signingConfig = signingConfigs.getByName("qa")
        }

        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}
kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}
