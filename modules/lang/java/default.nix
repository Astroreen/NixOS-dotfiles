{ pkgs, lib, config, ... }:
let 
    java-package = pkgs.jdk21;          # OpenJDK
    gradle-package = pkgs.gradle_8;     # Wrapped Gradle 8
    gradle-home = "${config.home.homeDirectory}/.gradle";

    settingsPath = "${config.home.homeDirectory}/.config/Code/User/settings.json";
    
    # Read existing settings if they exist
    existingSettings = 
        if builtins.pathExists settingsPath
        then builtins.fromJSON (builtins.readFile settingsPath)
        else {};
      
    # Java-specific settings to add
    javaSettings = {
        "java.configuration.detectJdksAtStart" = false;
        "java.configuration.updateBuildConfiguration" = "automatic";
        "java.compile.nullAnalysis.mode" = "automatic";
        "java.completion.enabled" = true;

        # Projects can use different Java versions
        "java.configuration.runtimes" = [
            {
                "name" = "JavaSE-11";
                "path" = "${pkgs.jdk11}/lib/openjdk";
                "default" = true;
            }
            {
                "name" = "JavaSE-21";
                "path" = "${pkgs.jdk21}/lib/openjdk";
            }
        ];
        
        "java.jdt.ls.java.home" = "${java-package}/lib/openjdk";
        "java.import.gradle.java.home" = "${java-package}/lib/openjdk";
        "java.home" = "${java-package}/lib/openjdk";                    # Depricated, but still used by some extensions
        "gradle.java.home" = "${java-package}/lib/openjdk";

        "java.import.gradle.enabled" = true;
        "java.import.gradle.wrapper.enabled" = true;

        "java.server.launchMode" = "Standard";
        "java.gradle.buildServer.enabled" = "on";

        "gradle.nestedProjects" = true;
        "gradle.autoDetect" = "off";

  
        # Auto-import settings
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

        # Auto-import on save
        "editor.codeActionsOnSave" = {
            "source.organizeImports" = "explicit";
        };

        # Enable parameter hints
        "editor.parameterHints.enabled" = true;
        "editor.suggest.snippetsPreventQuickSuggestions" = false;
        "editor.hover.enabled" = true;
        "editor.hover.delay" = 300;
    };
in
{
    # List of all Java versions I want to change between
    home.packages = with pkgs; [
        jdk11
        jdk21
    ];

    programs = {
        java = {
            enable = true;
            package = java-package;
        };

        gradle = {
            enable = true;
            package = gradle-package;
            home = "${gradle-home}";
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

    # home.sessionVariables = {
    #     lib.mkDefault JAVA_HOME = "${java-package}"; # /lib/openjdk
    #     lib.mkDefault GRADLE_USER_HOME = "${gradle-home}";
    # };
}
