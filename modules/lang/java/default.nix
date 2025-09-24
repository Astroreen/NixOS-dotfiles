{ pkgs, lib, config, ... }:
let 
    java-package = pkgs.jdk21;
    gradle-package = pkgs.gradle_8;
    gradle-home = ".gradle";

    settingsPath = "${config.home.homeDirectory}/.config/Code/User/settings.json";
    
    existingSettings = 
        if builtins.pathExists settingsPath
        then builtins.fromJSON (builtins.readFile settingsPath)
        else {};
      
    javaSettings = {
        "java.configuration.runtimes" = [
            {
                "name" = "JavaSE-11";
                "path" = "${pkgs.jdk11}/lib/openjdk";
                "default" = false;
            }
            {
                "name" = "JavaSE-17";
                "path" = "${pkgs.jdk17}/lib/openjdk";
                "default" = false;
            }
            {
                "name" = "JavaSE-21";
                "path" = "${pkgs.jdk21}/lib/openjdk";
                "default" = true;
            }
        ];

        "java.configuration.detectJdksAtStart" = false;
        "java.configuration.updateBuildConfiguration" = "automatic";
        "java.compile.nullAnalysis.mode" = "automatic";
        "java.completion.enabled" = true;
        
        "java.jdt.ls.java.home" = "${java-package}/lib/openjdk";
        "java.import.gradle.java.home" = "${java-package}/lib/openjdk";
        "gradle.java.home" = "${java-package}/lib/openjdk";
        "sonarlint.ls.javaHome" = "${java-package}";

        "java.import.gradle.enabled" = true;
        "java.import.gradle.wrapper.enabled" = true;
        "java.gradle.buildServer.enabled" = "on";
        "gradle.autoDetect" = "on";
        "gradle.nestedProjects" = true;
        "java.import.gradle.arguments" = "--no-daemon";
        
        "java.server.launchMode" = "Standard";
        "java.autobuild.enabled" = true;
        "java.completion.importOrder" = ["java" "javax" "com" "org"];
        "java.completion.favoriteStaticMembers" = [
            "org.junit.Assert.*"
            "org.junit.Assume.*"
            "org.junit.jupiter.api.Assertions.*"
        ];
        "java.completion.filteredTypes" = [
            "java.awt.*"
            "com.sun.*"
        ];

        "editor.codeActionsOnSave" = {
            "source.organizeImports" = "explicit";
        };

        "editor.parameterHints.enabled" = true;
        "editor.suggest.snippetsPreventQuickSuggestions" = false;
        "editor.hover.enabled" = true;
        "editor.hover.delay" = 300;
    };
in
{
    programs = {
        java = {
            enable = true;                                 # Avoid conflicts with home.packages
            package = java-package;
        };

        gradle = {
            enable = true;
            package = gradle-package;
            home = "${gradle-home}";
            settings = {
                "org.gradle.caching" = true;
                "org.gradle.parallel" = true;
                "org.gradle.java.home" = "${java-package}/lib/openjdk";
                # Disable daemon for multi-project compatibility
                "org.gradle.daemon" = false;
                "org.gradle.configureondemand" = true;
            };
        };

        vscode = {
            profiles.default.userSettings = existingSettings // javaSettings;
        };
    };

    # CRITICAL: Override JDT Language Server to use JDK17
    home.packages = with pkgs; [
        (jdt-language-server.override { jdk = jdk17; })     # This fixes the version mismatch
    ];

    home.sessionVariables = {
        # JAVA_HOME = "${java-package}/lib/openjdk";
        VSCODE_JAVA_HOME = "${java-package}/lib/openjdk";

        # GRADLE_USER_HOME = "${gradle-home}";
        # GRADLE_HOME = "${gradle-package}";
    };
}
