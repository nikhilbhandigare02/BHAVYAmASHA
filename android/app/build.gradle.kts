import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "io.uat.bhavya_maasha"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "io.uat.bhavya_maasha"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 19999
        versionName = "1.0.0"
    }

//    signingConfigs {
//        // create a release signing config using values from key.properties (if present)
//        create("release") {
//            // safe cast to String? - will be null if not present
//            keyAlias = keystoreProperties.getProperty("keyAlias")
//            keyPassword = keystoreProperties.getProperty("keyPassword")
//            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
//            storePassword = keystoreProperties.getProperty("storePassword")
//        }
//    }
//
//    buildTypes {
//        // configure release build to use signingConfig created above
//        getByName("release") {
//            signingConfig = signingConfigs.getByName("release")
//        }
//        // keep debug as is (or override if required)
//    }

    signingConfigs {
    // create a release signing config using values from key.properties (if present)
    create("release") {
        // safe cast to String? - will be null if not present
        keyAlias = keystoreProperties.getProperty("keyAlias")
        keyPassword = keystoreProperties.getProperty("keyPassword")
        storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
        storePassword = keystoreProperties.getProperty("storePassword")
    }
    // MODIFY existing debug config instead of creating it
    getByName("debug") {
        keyAlias = keystoreProperties.getProperty("keyAlias")
        keyPassword = keystoreProperties.getProperty("keyPassword")
        storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
        storePassword = keystoreProperties.getProperty("storePassword")
    }
}

    buildTypes {

        // configure release build to use signingConfig created above
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
        // keep debug as is (or override if required)
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }


//    buildTypes {
//        release {
//            // TODO: Add your own signing config for the release build.
//            // Signing with the debug keys for now, so `flutter run --release` works.
//            signingConfig = signingConfigs.getByName("debug")
//        }
//    }
}

flutter {
    source = "../.."
}
