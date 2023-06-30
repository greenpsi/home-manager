{ config, lib, pkgs, ... }:

let

  cfg = config.services.copyq;

in {
  meta.maintainers = [ lib.maintainers.DamienCassou ];

  options.services.copyq = {
    enable = lib.mkEnableOption
      (lib.mdDoc "CopyQ, a clipboard manager with advanced features");

    package = lib.mkPackageOptionMD pkgs "copyq" { };

    systemdTarget = lib.mkOption {
      type = lib.types.str;
      default = "graphical-session.target";
      example = "sway-session.target";
      description = lib.mdDoc ''
        The systemd target that will automatically start the CopyQ service.

        When setting this value to `"sway-session.target"`,
        make sure to also enable {option}`wayland.windowManager.sway.systemd.enable`,
        otherwise the service may never be started.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.copyq" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.copyq = {
      Unit = {
        Description = "CopyQ clipboard management daemon";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${cfg.package}/bin/copyq";
        Restart = "on-failure";
        Environment = [ "QT_QPA_PLATFORM=xcb" ];
      };

      Install = { WantedBy = [ cfg.systemdTarget ]; };
    };
  };
}
