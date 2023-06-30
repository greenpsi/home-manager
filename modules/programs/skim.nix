{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.skim;

in {
  options.programs.skim = {
    enable = mkEnableOption (lib.mdDoc "skim - a command-line fuzzy finder");

    package = mkOption {
      type = types.package;
      default = pkgs.skim;
      defaultText = literalExpression "pkgs.skim";
      description = lib.mdDoc "Package providing the {command}`skim` tool.";
    };

    defaultCommand = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "fd --type f";
      description = lib.mdDoc ''
        The command that gets executed as the default source for skim
        when running.
      '';
    };

    defaultOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--height 40%" "--prompt ⟫" ];
      description = lib.mdDoc ''
        Extra command line options given to skim by default.
      '';
    };

    fileWidgetCommand = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "fd --type f";
      description = lib.mdDoc ''
        The command that gets executed as the source for skim for the
        CTRL-T keybinding.
      '';
    };

    fileWidgetOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--preview 'head {}'" ];
      description = lib.mdDoc ''
        Command line options for the CTRL-T keybinding.
      '';
    };

    changeDirWidgetCommand = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "fd --type d";
      description = lib.mdDoc ''
        The command that gets executed as the source for skim for the
        ALT-C keybinding.
      '';
    };

    changeDirWidgetOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--preview 'tree -C {} | head -200'" ];
      description = lib.mdDoc ''
        Command line options for the ALT-C keybinding.
      '';
    };

    historyWidgetOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--tac" "--exact" ];
      description = lib.mdDoc ''
        Command line options for the CTRL-R keybinding.
      '';
    };

    enableBashIntegration = mkOption {
      default = true;
      type = types.bool;
      description = lib.mdDoc ''
        Whether to enable Bash integration.
      '';
    };

    enableZshIntegration = mkOption {
      default = true;
      type = types.bool;
      description = lib.mdDoc ''
        Whether to enable Zsh integration.
      '';
    };

    enableFishIntegration = mkOption {
      default = true;
      type = types.bool;
      description = lib.mdDoc ''
        Whether to enable Fish integration.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.sessionVariables = mapAttrs (n: v: toString v)
      (filterAttrs (n: v: v != [ ] && v != null) {
        SKIM_ALT_C_COMMAND = cfg.changeDirWidgetCommand;
        SKIM_ALT_C_OPTS = cfg.changeDirWidgetOptions;
        SKIM_CTRL_R_OPTS = cfg.historyWidgetOptions;
        SKIM_CTRL_T_COMMAND = cfg.fileWidgetCommand;
        SKIM_CTRL_T_OPTS = cfg.fileWidgetOptions;
        SKIM_DEFAULT_COMMAND = cfg.defaultCommand;
        SKIM_DEFAULT_OPTIONS = cfg.defaultOptions;
      });

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      if [[ :$SHELLOPTS: =~ :(vi|emacs): ]]; then
        . ${cfg.package}/share/skim/completion.bash
        . ${cfg.package}/share/skim/key-bindings.bash
      fi
    '';

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      if [[ $options[zle] = on ]]; then
        . ${cfg.package}/share/skim/completion.zsh
        . ${cfg.package}/share/skim/key-bindings.zsh
      fi
    '';

    programs.fish.shellInit = mkIf cfg.enableFishIntegration ''
      source ${cfg.package}/share/skim/key-bindings.fish && skim_key_bindings
    '';
  };
}
