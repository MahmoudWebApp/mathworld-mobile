import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeystoreProperties = Properties()
val releaseKeystoreFile = rootProject.file("key.properties")
if (releaseKeystoreFile.exists()) {
    releaseKeystoreFile.inputStream().use { releaseKeystoreProperties.load(it) }
}
val hasReleaseSigning = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
    .all { !releaseKeystoreProperties.getProperty(it).isNullOrBlank() }

// Only manual-test CI APKs opt in. The production appId, signing and label
// remain unchanged for every ordinary Android build.
val isolatedQaApk = System.getenv("MATHWORLD_ISOLATED_QA_APK") == "true"

// Unlike the Android debug keystore generated separately on each CI runner,
// the isolated QA variant requires a persistent signing key provided through
// repository secrets. It must never fall back to an ephemeral key.
val qaSigningEnvironment = listOf(
    "MATHWORLD_QA_KEYSTORE_FILE",
    "MATHWORLD_QA_STORE_PASSWORD",
    "MATHWORLD_QA_KEY_ALIAS",
    "MATHWORLD_QA_KEY_PASSWORD",
)
val hasQaSigning = qaSigningEnvironment.all { !System.getenv(it).isNullOrBlank() }
if (isolatedQaApk && !hasQaSigning) {
    throw GradleException("Isolated QA builds require a persistent QA keystore and all signing environment variables.")
}

android {
    namespace = "com.mathworld.mathworld_mobile"
    compileSdk = flutter.compileSdkVersion
    // Pin a stable NDK installed on CI images; avoid Flutter's newer flaky download.
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.mathworld.mathworld_mobile"
        manifestPlaceholders["mathworldAppLabel"] = "MathWorld"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasQaSigning) {
            create("isolatedQaRelease") {
                storeFile = file(System.getenv("MATHWORLD_QA_KEYSTORE_FILE"))
                storePassword = System.getenv("MATHWORLD_QA_STORE_PASSWORD")
                keyAlias = System.getenv("MATHWORLD_QA_KEY_ALIAS")
                keyPassword = System.getenv("MATHWORLD_QA_KEY_PASSWORD")
            }
        }
        if (hasReleaseSigning) {
            create("productionRelease") {
                storeFile = file(releaseKeystoreProperties.getProperty("storeFile"))
                storePassword = releaseKeystoreProperties.getProperty("storePassword")
                keyAlias = releaseKeystoreProperties.getProperty("keyAlias")
                keyPassword = releaseKeystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Isolated QA builds coexist with the user's existing MathWorld
            // installation, avoiding Android's signature-mismatch rejection.
            if (isolatedQaApk) {
                applicationIdSuffix = ".qa"
                versionNameSuffix = "-qa"
                manifestPlaceholders["mathworldAppLabel"] = "MathWorld QA"
            }
            // Without a production keystore, CI builds are debug-signed QA only.
            signingConfig = when {
                isolatedQaApk -> signingConfigs.getByName("isolatedQaRelease")
                hasReleaseSigning -> signingConfigs.getByName("productionRelease")
                else -> {
                    logger.warn("MathWorld: ONE-OFF DEBUG-SIGNED APK; updates may fail across CI runs.")
                    signingConfigs.getByName("debug")
                }
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
