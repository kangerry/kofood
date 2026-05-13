plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream
import org.gradle.api.tasks.Exec

val localProps = Properties()
val localPropsFile = rootProject.file("local.properties")
if (localPropsFile.exists()) {
    FileInputStream(localPropsFile).use { fis -> localProps.load(fis) }
}
val mapsApiKey: String = (localProps.getProperty("MAPS_API_KEY") ?: System.getenv("MAPS_API_KEY")) ?: ""

android {
    namespace = "com.example.komera_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }
    // packagingOptions purposely left default; splits will handle ABIs

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.komera_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["mapsApiKey"] = mapsApiKey
        // ndk abiFilters removed to avoid conflict with splits ABI
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

tasks.register<Exec>("installDebugOnEmulator") {
    dependsOn("assembleDebug")
    val apkPath = file("$buildDir/outputs/apk/debug/app-debug.apk").absolutePath
    commandLine(
        "C:/Users/acer/AppData/Local/Android/Sdk/platform-tools/adb.exe",
        "-s",
        "emulator-5554",
        "install",
        "-r",
        apkPath
    )
}

tasks.register<Exec>("runDebugOnEmulator") {
    dependsOn("installDebugOnEmulator")
    commandLine(
        "C:/Users/acer/AppData/Local/Android/Sdk/platform-tools/adb.exe",
        "-s",
        "emulator-5554",
        "shell",
        "am",
        "start",
        "-n",
        "com.example.komera_mobile/com.example.komera_mobile.MainActivity"
    )
}
