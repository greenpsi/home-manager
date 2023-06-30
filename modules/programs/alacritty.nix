{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.alacritty;
  yamlFormat = pkgs.formats.yaml { };
in {
  options = {
    programs.alacritty = {
      enable = mkEnableOption (lib.mdDoc "Alacritty");

      package = mkOption {
        type = types.package;
        default = pkgs.alacritty;
        defaultText = literalExpression "pkgs.alacritty";
        description = lib.mdDoc "The Alacritty package to install.";
      };

      settings = mkOption {
        type = yamlFormat.type;
        default = { };
        example = literalExpression ''
          {
            window.dimensions = {
              lines = 3;
              columns = 200;
            };
            key_bindings = [
              {
                key = "K";
                mods = "Control";
                chars = "\\x0c";
              }
            ];
          }
        '';
        description = lib.mdDoc ''
          Configuration written to
          {file}`$XDG_CONFIG_HOME/alacritty/alacritty.yml`. See
          <https://github.com/alacritty/alacritty/blob/master/alacritty.yml>
          for the default configuration.
        '';
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      home.packages = [ cfg.package ];

      xdg.configFile."alacritty/alacritty.yml" = mkIf (cfg.settings != { }) {
        # TODO: Replace by the generate function but need to figure out how to
        # handle the escaping first.
        #
        # source = yamlFormat.generate "alacritty.yml" cfg.settings;

        text =
          replaceStrings [ "\\\\" ] [ "\\" ] (builtins.toJSON cfg.settings);
      };
    })
  ];
}
