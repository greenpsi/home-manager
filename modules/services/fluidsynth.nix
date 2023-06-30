{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.fluidsynth;

in {
  meta.maintainers = [ maintainers.valodim ];

  options = {
    services.fluidsynth = {
      enable = mkEnableOption (lib.mdDoc "fluidsynth midi synthesizer");

      soundFont = mkOption {
        type = types.path;
        default = "${pkgs.soundfont-fluid}/share/soundfonts/FluidR3_GM2-2.sf2";
        description = lib.mdDoc ''
          The soundfont file to use, in SoundFont 2 format.
        '';
      };

      soundService = mkOption {
        type = types.enum [ "jack" "pipewire-pulse" "pulseaudio" ];
        default = "pulseaudio";
        example = "pipewire-pulse";
        description = lib.mdDoc ''
          The systemd sound service to depend on.
        '';
      };

      extraOptions = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "--sample-rate 96000" ];
        description = lib.mdDoc ''
          Extra arguments, added verbatim to the fluidsynth command. See
          {manpage}`fluidsynth.conf(1)`.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.fluidsynth" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services.fluidsynth = {
      Unit = {
        Description = "FluidSynth Daemon";
        Documentation = "man:fluidsynth(1)";
        BindsTo = [ (cfg.soundService + ".service") ];
        After = [ (cfg.soundService + ".service") ];
      };

      Install = { WantedBy = [ "default.target" ]; };

      Service = {
        ExecStart = "${pkgs.fluidsynth}/bin/fluidsynth -a pulseaudio -si ${
            lib.concatStringsSep " " cfg.extraOptions
          } ${cfg.soundFont}";
      };
    };
  };
}
