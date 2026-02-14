{
  pkgs,
  lib,
  config,
  ...
}:
let
  java-package = pkgs.jdk25;
  gradle-package = pkgs.gradle_8;
  gradle-home = ".gradle";

  settingsPath = "${config.home.homeDirectory}/.config/Code/User/settings.json";

  existingSettings =
    if builtins.pathExists settingsPath then
      builtins.fromJSON (builtins.readFile settingsPath)
    else
      { };

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
        "default" = false;
      }
      {
        "name" = "JavaSE-25";
        "path" = "${pkgs.jdk25}/lib/openjdk";
        "default" = true;
      }
    ];

    "java.configuration.detectJdksAtStart" = false;
    "java.configuration.updateBuildConfiguration" = "automatic";
    "java.compile.nullAnalysis.mode" = "automatic";
    "java.completion.enabled" = true;

    "java.jdt.ls.java.home" = "${pkgs.jdk25}";
    "java.import.gradle.java.home" = "${java-package}";
    "gradle.java.home" = "${java-package}";
    "sonarlint.ls.javaHome" = "${java-package}";

    "java.import.gradle.enabled" = true;
    "java.import.gradle.wrapper.enabled" = true;
    "java.gradle.buildServer.enabled" = "on";
    "gradle.autoDetect" = "on";
    "gradle.nestedProjects" = true;
    # Give the server 4GB of RAM
    "java.jdt.ls.vmargs" = "-Xmx4G -XX:+UseG1GC -XX:+UseStringDeduplication";
    # Start in Lightweight mode to stop it from building everything immediately
    "java.server.launchMode" = "Standard";
    # IMPORTANT: Stop it from indexing your Nix environment folders
    "files.exclude" = {
      "**/.devenv/**" = true;
      "**/.direnv/**" = true;
      "**/target/**" = true;
      "**/bin/**" = true;
    };
    "files.watcherExclude" = {
      "**/.devenv/**" = true;
      "**/.direnv/**" = true;
      "**/target/**" = true;
      "**/bin/**" = true;
    };
    "java.import.exclusions" = [
      "**/node_modules/**"
      "**/.metadata/**"
      "**/archetype-resources/**"
      "**/META-INF/maven/**"
      "**/.devenv/**" # This is the crucial one
      "**/.direnv/**"
    ];
    "java.project.resourceFilters" = [
      "node_modules"
      ".devenv"
      ".direnv"
    ];

    "java.autobuild.enabled" = true;
    "java.completion.importOrder" = [
      "java"
      "javax"
      "com"
      "org"
    ];
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
    "editor.hover.enabled" = "on";
    "editor.hover.delay" = 300;

    # Java Formatter
    "[java]" = {
      "editor.defaultFormatter" = "redhat.java";
      "editor.tabSize" = 4;
    };

    # SonarLint settings
    "sonarlint.rules" = {
      "java:S1452" = {
        "level" = "off";
      };
      "java:S3776" = {
        "level" = "off";
      };
    };

    # JavaFX settings
    "javafx.libPath" = "/home/astroreen/.local/share/javafx/javafx-sdk-25.0.2/lib";
  };
in
{
  programs = {
    java = {
      enable = true; # Avoid conflicts with home.packages
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
        # Disable daemon for multi-project compatibility
        "org.gradle.daemon" = false;
        "org.gradle.configureondemand" = true;
      };
    };

    vscode = {
      profiles.default.userSettings = existingSettings // javaSettings;
    };
  };

  home.packages = with pkgs; [
    javaPackages.openjfx25
    maven
  ];

  # Remove the JRE that comes bundled with the Red Hat Java extension to avoid conflicts
  home.activation.deleteVscodeJre = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -d ${config.home.homeDirectory}/.vscode/extensions/redhat.java-*/jre ]; then
      $DRY_RUN_CMD rm -rf ${config.home.homeDirectory}/.vscode/extensions/redhat.java-*/jre
    fi
  '';

  home.sessionVariables = {
    # JAVA_HOME = "${java-package}/lib/openjdk";
    VSCODE_JAVA_HOME = "${java-package}";

    # GRADLE_USER_HOME = "${gradle-home}";
    # GRADLE_HOME = "${gradle-package}";
  };
}
