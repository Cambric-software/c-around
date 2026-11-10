allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Force compileSdk 36 for all subprojects — sqflite_android 2.4.4+ uses
// VERSION_CODES.BAKLAVA and Thread.threadId() which require SDK 36.
subprojects {
    afterEvaluate {
        extensions.findByName("android")?.let { ext ->
            val android = ext as? com.android.build.gradle.BaseExtension ?: return@let
            if (android.compileSdkVersion != "android-36") {
                android.compileSdkVersion(36)
            }
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
