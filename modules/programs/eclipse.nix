{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.eclipse;

in {
  meta.maintainers = [ maintainers.rycee ];

  options = {
    programs.eclipse = {
      enable = mkEnableOption (lib.mdDoc "Eclipse");

      package = mkOption {
        type = types.package;
        default = pkgs.eclipses.eclipse-platform;
        defaultText = literalExpression "pkgs.eclipses.eclipse-platform";
        example = literalExpression "pkgs.eclipses.eclipse-java";
        description = lib.mdDoc ''
          The Eclipse package to install.
        '';
      };

      enableLombok = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = lib.mdDoc ''
          Whether to enable the Lombok Java Agent in Eclipse. This is
          necessary to use the Lombok class annotations.
        '';
      };

      jvmArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = lib.mdDoc "JVM arguments to use for the Eclipse process.";
      };

      plugins = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = lib.mdDoc "Plugins that should be added to Eclipse.";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      (pkgs.eclipses.eclipseWithPlugins {
        eclipse = cfg.package;
        jvmArgs = cfg.jvmArgs ++ optional cfg.enableLombok
          "-javaagent:${pkgs.lombok}/share/java/lombok.jar";
        plugins = cfg.plugins;
      })
    ];
  };
}
