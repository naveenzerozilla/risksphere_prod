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

        // Load properties for secure credentials injection
        val localProperties = java.util.Properties()
        val localPropertiesFile = rootProject.file("local.properties")
        if (localPropertiesFile.exists()) {
            localProperties.load(localPropertiesFile.inputStream())
        }

        manifestPlaceholders["appAuthRedirectScheme"] = "com.risksphere.green"
        manifestPlaceholders["mapsApiKey"] = localProperties.getProperty("maps.api.key") ?: ""
        manifestPlaceholders["admobAppId"] = localProperties.getProperty("admob.app.id") ?: ""
    }

    // Load properties at root level of android block for signing configurations
    val localProperties = java.util.Properties()
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localProperties.load(localPropertiesFile.inputStream())
    }

    signingConfigs {
        create("release") {
            val path = localProperties.getProperty("signing.storeFilePath") ?: ""
            storeFile = if (path.isNotEmpty()) file(path) else null
            storePassword = localProperties.getProperty("signing.storePassword") ?: ""
            keyAlias = localProperties.getProperty("signing.keyAlias") ?: ""
            keyPassword = localProperties.getProperty("signing.keyPassword") ?: ""
        }

        create("qa") {
            val path = localProperties.getProperty("signing.storeFilePath") ?: ""
            storeFile = if (path.isNotEmpty()) file(path) else null
            storePassword = localProperties.getProperty("signing.storePassword") ?: ""
            keyAlias = localProperties.getProperty("signing.keyAlias") ?: ""
            keyPassword = localProperties.getProperty("signing.keyPassword") ?: ""
        }

        getByName("debug") {
            val path = localProperties.getProperty("signing.storeFilePath") ?: ""
            storeFile = if (path.isNotEmpty()) file(path) else null
            storePassword = localProperties.getProperty("signing.storePassword") ?: ""
            keyAlias = localProperties.getProperty("signing.keyAlias") ?: ""
            keyPassword = localProperties.getProperty("signing.keyPassword") ?: ""
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
