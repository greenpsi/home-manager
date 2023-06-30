{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.programs.boxxy;

  configPath = "${config.xdg.configHome}/boxxy/boxxy.yaml";
  settingsFormat = pkgs.formats.yaml { };

  boxxyRulesOpts = types.submodule {
    freeformType = settingsFormat.type;

    options = {
      name = mkOption {
        type = types.str;
        description = lib.mdDoc ''
          Unique identifier of the boxxy rule. This can be any single-line string.
        '';
      };

      target = mkOption {
        type = types.str;
        default = "";
        example = "~/.ssh";
        description = lib.mdDoc ''
          What directory/file to redirect.
        '';
      };

      rewrite = mkOption {
        type = types.str;
        default = "";
        example = literalExpression ''"''${config.xdg.configHome}/ssh"'';
        description = lib.mdDoc ''
          Where that file/directory should be rewritten to.
        '';
      };

      mode = mkOption {
        type = types.enum [ "file" "directory" ];
        default = "directory";
        description = lib.mdDoc ''
          Does the current path redirect a file or a directory?
        '';
      };

      only = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = literalExpression ''
          [
            "bash"
            "/usr/bin/sh"
          ]
        '';
        description = lib.mdDoc ''
          Apply redirection ONLY to specified executable names.
        '';
      };

      context = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "/home/example/Projects/my-project" ];
        description = lib.mdDoc ''
          Apply redirection ONLY when in a certain directory.
        '';
      };

      env = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = literalExpression ''
          {
            MY_ENV_VAR = "my_env_var_value";
          }
        '';
        description = lib.mdDoc ''
          Give certain environment variables for said match.
        '';
      };
    };
  };
in {
  options.programs.boxxy = {
    enable =
      mkEnableOption (lib.mdDoc "boxxy: Boxes in badly behaving applications");

    package = mkPackageOptionMD pkgs "boxxy" { };

    rules = mkOption {
      type = types.listOf boxxyRulesOpts;
      default = [ ];
      description = lib.mdDoc "List of boxxy rules";
    };
  };

  config = mkIf cfg.enable {
    assertions =
      [ (hm.assertions.assertPlatform "programs.boxxy" pkgs platforms.linux) ];

    home.file = mkIf (cfg.rules != [ ]) {
      "${configPath}".source =
        settingsFormat.generate "boxxy-config.yaml" { rules = cfg.rules; };
    };

    home.packages = [ cfg.package ];
  };

  meta.maintainers = with lib.hm.maintainers; [ nikp123 ];
}

