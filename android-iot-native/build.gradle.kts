plugins {
    id("com.android.library")
    kotlin("android")
    id("kotlin-kapt")
}

val coreKtxVersion = "1.13.1"
val lifecycleVersion = "2.8.6"
val activityVersion = "1.9.2"
val roomVersion = "2.6.1"
val coroutinesVersion = "1.8.1"

android {
    namespace = "com.example.iot.nativekit"
    compileSdk = 34

    defaultConfig {
        minSdk = 26
        targetSdk = 34
        consumerProguardFiles("consumer-rules.pro")
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:$coreKtxVersion")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:$lifecycleVersion")
    implementation("androidx.activity:activity-ktx:$activityVersion")
    implementation("androidx.room:room-runtime:$roomVersion")
    kapt("androidx.room:room-compiler:$roomVersion")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:$coroutinesVersion")
}
