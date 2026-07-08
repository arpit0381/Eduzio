allprojects {
    repositories {
        google()
        mavenCentral()
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
    afterEvaluate {
        val extension = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        if (extension != null) {
            // Force compileSdkVersion to 36 to resolve connectivity_plus and newer AndroidX library dependency errors
            extension.compileSdkVersion(36)

            // Set namespace if it is missing
            if (extension.namespace == null) {
                val groupPath = project.group.toString()
                extension.namespace = if (groupPath.isNotEmpty()) groupPath else "com.eduzio.${project.name.replace("-", "_")}"
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
