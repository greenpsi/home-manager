{ config, lib, pkgs, ... }:
with lib;
let cfg = config.services.clipman;
in {
  meta.maintainers = [ maintainers.jwygoda ];

  options.services.clipman = {
    enable = mkEnableOption
      (lib.mdDoc "clipman, a simple clipboard manager for Wayland");

    package = mkPackageOptionMD pkgs "clipman" { };

    systemdTarget = mkOption {
      type = types.str;
      default = "graphical-session.target";
      example = "sway-session.target";
      description = lib.mdDoc ''
        The systemd target that will automatically start the clipman service.

        When setting this value to `"sway-session.target"`,
        make sure to also enable {option}`wayland.windowManager.sway.systemd.enable`,
        otherwise the service may never be started.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.clipman" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.clipman = {
      Unit = {
        Description = "Clipboard management daemon";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart =
          "${pkgs.wl-clipboard}/bin/wl-paste -t text --watch ${cfg.package}/bin/clipman store";
        ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
        Restart = "on-failure";
        KillMode = "mixed";
      };

      Install = { WantedBy = [ cfg.systemdTarget ]; };
    };
  };
}
