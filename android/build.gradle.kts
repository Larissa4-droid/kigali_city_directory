import java.io.File
import org.gradle.api.tasks.Delete

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Place the Android build outputs in the workspace-level `build/` directory
// (one level up from the android/ directory). This matches the original intent
// of moving build artifacts to the workspace `build` folder.
val workspaceBuildDir = File(rootDir, "../build")
rootProject.buildDir = workspaceBuildDir

// Put each subproject's build outputs under workspaceBuildDir/<projectName>
subprojects {
    project.buildDir = File(rootProject.buildDir, project.name)
}

// Ensure :app is evaluated early when required by other modules.
// Only evaluate :app if the project actually exists to avoid configuration errors.
rootProject.findProject(":app")?.let {
    evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
