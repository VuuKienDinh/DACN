plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.doanchuyennganh"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.doanchuyennganh"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Tự động mở cầu nối USB (adb reverse tcp:5080 tcp:5080) mỗi khi bấm Run trên máy thật
val adbExecutableProvider = androidComponents.sdkComponents.adb
val setupAdbReverse by tasks.registering {
    outputs.upToDateWhen { false }
    doLast {
        runCatching {
            val adbPath = adbExecutableProvider.get().asFile.absolutePath
            val listProc = ProcessBuilder(adbPath, "devices").redirectErrorStream(true).start()
            val output = listProc.inputStream.bufferedReader().readText()
            listProc.waitFor()

            output.lineSequence().drop(1).forEach { line ->
                val parts = line.trim().split(Regex("\\s+"))
                if (parts.size >= 2 && parts[1] == "device" && !parts[0].startsWith("emulator-")) {
                    ProcessBuilder(adbPath, "-s", parts[0], "reverse", "tcp:5080", "tcp:5080")
                        .redirectErrorStream(true)
                        .start()
                        .waitFor()
                }
            }
        }
    }
}

tasks.matching {
    it.name == "assembleDebug" || it.name == "assembleProfile" || it.name == "assembleRelease"
}.configureEach {
    dependsOn(setupAdbReverse)
}
