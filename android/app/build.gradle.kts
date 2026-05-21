import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// PR21: 카카오 네이티브 앱 키는 *Dart*가 아닌 *AndroidManifest의 scheme*에도
// 들어가야 한다(`kakao{KEY}://oauth`). gitignored인 local.properties에 한 줄
// 박아두면 빌드 시 manifestPlaceholder로 자동 주입. 키 없으면 빈 placeholder가
// 들어가 카카오 OAuth는 작동하지 않지만 빌드 자체는 통과한다.
//   local.properties 한 줄: kakao.nativeAppKey=abc123...
val localProps = Properties().apply {
    val f = rootProject.file("local.properties")
    if (f.exists()) FileInputStream(f).use { load(it) }
}
val kakaoNativeAppKey: String =
    localProps.getProperty("kakao.nativeAppKey") ?: ""

android {
    namespace = "io.github.tgparkk.bookquote"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "io.github.tgparkk.bookquote"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // PR21: AndroidManifest의 ${KAKAO_NATIVE_APP_KEY} placeholder 주입.
        manifestPlaceholders["KAKAO_NATIVE_APP_KEY"] = kakaoNativeAppKey
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
