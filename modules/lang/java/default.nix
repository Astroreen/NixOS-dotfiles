{ pkgs, lib, config, ... }:
let 
    java-package = pkgs.jdk;            # OpenJDK 21
    gradle-package = pkgs.gradle_8;     # Wrapped Gradle 8
    gradle-home = ".gradle";

    settingsPath = "${config.home.homeDirectory}/.config/Code/User/settings.json";
    
    # Read existing settings if they exist
    existingSettings = 
        if builtins.pathExists settingsPath
        then builtins.fromJSON (builtins.readFile settingsPath)
        else {};
      
    # Java-specific settings to add
    javaSettings = {
        "java.configuration.updateBuildConfiguration" = "automatic";
        "java.compile.nullAnalysis.mode" = "automatic";
        "java.jdt.ls.java.home" = "${java-package}";
        "java.import.gradle.enabled" = true;
        "java.import.gradle.wrapper.enabled" = true;
        "gradle.nestedProjects" = true;
        "gradle.autoDetect" = "on";
    };
in
{
    programs = {
        java = {
            enable = true;
            package = java-package;
        };

        gradle = {
            enable = true;
            package = gradle-package;
            # home = "${gradle-home}";
            settings = {
                "org.gradle.caching" = true;
                "org.gradle.parallel" = true;
                "org.gradle.java.home" = "${java-package}";
            };
        };

        vscode = {
            # Merge existing settings with Java settings
            profiles.default.userSettings = existingSettings // javaSettings;
        };
    };

    home.sessionVariables = {
        JAVA_HOME = "${java-package}/lib/openjdk";
        GRADLE_USER_HOME = "$HOME/${gradle-home}";
    };
}
