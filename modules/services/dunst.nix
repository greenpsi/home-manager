{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.dunst;

  eitherStrBoolIntList = with types;
    either str (either bool (either int (listOf str)));

  toDunstIni = generators.toINI {
    mkKeyValue = key: value:
      let
        value' = if isBool value then
          (lib.hm.booleans.yesNo value)
        else if isString value then
          ''"${value}"''
        else
          toString value;
      in "${key}=${value'}";
  };

  themeType = types.submodule {
    options = {
      package = mkOption {
        type = types.package;
        example = literalExpression "pkgs.gnome.adwaita-icon-theme";
        description = lib.mdDoc "Package providing the theme.";
      };

      name = mkOption {
        type = types.str;
        example = "Adwaita";
        description = lib.mdDoc "The name of the theme within the package.";
      };

      size = mkOption {
        type = types.str;
        default = "32x32";
        example = "16x16";
        description = lib.mdDoc "The desired icon size.";
      };
    };
  };

  hicolorTheme = {
    package = pkgs.hicolor-icon-theme;
    name = "hicolor";
    size = "32x32";
  };

in {
  meta.maintainers = [ maintainers.rycee ];

  options = {
    services.dunst = {
      enable = mkEnableOption (lib.mdDoc "the dunst notification daemon");

      package = mkOption {
        type = types.package;
        default = pkgs.dunst;
        defaultText = literalExpression "pkgs.dunst";
        description = lib.mdDoc "Package providing {command}`dunst`.";
      };

      configFile = mkOption {
        type = with types; either str path;
        default = "${config.xdg.configHome}/dunst/dunstrc";
        defaultText = "$XDG_CONFIG_HOME/dunst/dunstrc";
        description = lib.mdDoc ''
          Path to the configuration file read by dunst.

          Note that the configuration generated by Home Manager will be
          written to {file}`$XDG_CONFIG_HOME/dunst/dunstrc`
          regardless. This allows using a mutable configuration file generated
          from the immutable one, useful in scenarios where live reloading is
          desired.
        '';
      };

      iconTheme = mkOption {
        type = themeType;
        default = hicolorTheme;
        description = lib.mdDoc "Set the icon theme.";
      };

      waylandDisplay = mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc
          "Set the service's {env}`WAYLAND_DISPLAY` environment variable.";
      };

      settings = mkOption {
        type = types.submodule {
          freeformType = with types; attrsOf (attrsOf eitherStrBoolIntList);
          options = {
            global.icon_path = mkOption {
              type = types.separatedString ":";
              description = lib.mdDoc "Paths where dunst will look for icons.";
            };
          };
        };
        default = { };
        description = lib.mdDoc
          "Configuration written to {file}`$XDG_CONFIG_HOME/dunst/dunstrc`.";
        example = literalExpression ''
          {
            global = {
              width = 300;
              height = 300;
              offset = "30x50";
              origin = "top-right";
              transparency = 10;
              frame_color = "#eceff1";
              font = "Droid Sans 9";
            };

            urgency_normal = {
              background = "#37474f";
              foreground = "#eceff1";
              timeout = 10;
            };
          };
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        (hm.assertions.assertPlatform "services.dunst" pkgs platforms.linux)
      ];

      home.packages = [ cfg.package ];

      xdg.dataFile."dbus-1/services/org.knopwob.dunst.service".source =
        "${pkgs.dunst}/share/dbus-1/services/org.knopwob.dunst.service";

      services.dunst.settings.global.icon_path = let
        useCustomTheme = cfg.iconTheme.package != hicolorTheme.package
          || cfg.iconTheme.name != hicolorTheme.name || cfg.iconTheme.size
          != hicolorTheme.size;

        basePaths = [
          "/run/current-system/sw"
          config.home.profileDirectory
          cfg.iconTheme.package
        ] ++ optional useCustomTheme hicolorTheme.package;

        themes = [ cfg.iconTheme ] ++ optional useCustomTheme
          (hicolorTheme // { size = cfg.iconTheme.size; });

        categories = [
          "actions"
          "animations"
          "apps"
          "categories"
          "devices"
          "emblems"
          "emotes"
          "filesystem"
          "intl"
          "legacy"
          "mimetypes"
          "places"
          "status"
          "stock"
        ];

        mkPath = { basePath, theme, category }:
          "${basePath}/share/icons/${theme.name}/${theme.size}/${category}";
      in concatMapStringsSep ":" mkPath (cartesianProductOfSets {
        basePath = basePaths;
        theme = themes;
        category = categories;
      });

      systemd.user.services.dunst = {
        Unit = {
          Description = "Dunst notification daemon";
          After = [ "graphical-session-pre.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          Type = "dbus";
          BusName = "org.freedesktop.Notifications";
          ExecStart = "${cfg.package}/bin/dunst -config ${cfg.configFile}";
          Environment = optionalString (cfg.waylandDisplay != "")
            "WAYLAND_DISPLAY=${cfg.waylandDisplay}";
        };
      };
    }

    (mkIf (cfg.settings != { }) {
      xdg.configFile."dunst/dunstrc" = {
        text = toDunstIni cfg.settings;
        onChange = ''
          ${pkgs.procps}/bin/pkill -u "$USER" ''${VERBOSE+-e} dunst || true
        '';
      };
    })
  ]);
}
