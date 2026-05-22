import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase Crashlytics (PR26) — google-services가 google-services.json을 읽어
    // Firebase 설정 리소스를 생성, crashlytics가 release 빌드 매핑 파일을 업로드.
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
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

// release 서명 키 — gitignored인 key.properties가 있으면 release 키로 서명한다.
// 없으면 debug 키로 폴백(키스토어 없는 환경에서 `flutter run --release`·CI가
// 깨지지 않게). Play Store 업로드용 빌드는 key.properties가 반드시 있어야 한다.
val keystorePropsFile = rootProject.file("key.properties")
val keystoreProps = Properties().apply {
    if (keystorePropsFile.exists()) FileInputStream(keystorePropsFile).use { load(it) }
}

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

    signingConfigs {
        if (keystorePropsFile.exists()) {
            create("release") {
                keyAlias = keystoreProps.getProperty("keyAlias")
                keyPassword = keystoreProps.getProperty("keyPassword")
                storeFile = keystoreProps.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProps.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // key.properties가 있으면 release 키로, 없으면 debug 키로 폴백 서명.
            signingConfig = if (keystorePropsFile.exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
