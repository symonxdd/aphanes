import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing details, from whichever source is available.
//
// Locally that is android/key.properties, which is gitignored and which
// most contributors will not have. In CI it is environment variables fed
// from repository secrets. When neither is present the release build
// falls back to the debug key below, so `flutter build apk --release`
// still works for anyone who just wants to try it.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) {
        file.inputStream().use { load(it) }
    }
}

fun signingValue(propertyKey: String, envKey: String): String? =
    keystoreProperties.getProperty(propertyKey) ?: System.getenv(envKey)

val keystorePath = signingValue("storeFile", "ANDROID_KEYSTORE_PATH")
val hasReleaseSigning = keystorePath != null && file(keystorePath).exists()

android {
    namespace = "me.symon.aphanes"
    // flutter_secure_storage requires compileSdk 37; flutter.compileSdkVersion
    // (the Flutter SDK's own bundled default) hasn't caught up yet.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "me.symon.aphanes"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(keystorePath!!)
                storePassword = signingValue("storePassword", "ANDROID_KEYSTORE_PASSWORD")
                keyAlias = signingValue("keyAlias", "ANDROID_KEY_ALIAS")
                keyPassword = signingValue("keyPassword", "ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            // The real key when one is configured, the debug key otherwise.
            // Only the former produces an APK that can be installed over a
            // previous release, so the release workflow always supplies it;
            // the fallback exists purely so a local release build does not
            // fail for someone without the keystore.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
