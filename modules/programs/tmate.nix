{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.tmate;

in {
  meta.maintainers = [ maintainers.jlesquembre ];

  options = {
    programs.tmate = {
      enable = mkEnableOption (lib.mdDoc "tmate");

      package = mkOption {
        type = types.package;
        default = pkgs.tmate;
        defaultText = literalExpression "pkgs.tmate";
        example = literalExpression "pkgs.tmate";
        description = lib.mdDoc "The tmate package to install.";
      };

      host = mkOption {
        type = with types; nullOr str;
        default = null;
        example = literalExpression "tmate.io";
        description = lib.mdDoc "Tmate server address.";
      };

      port = mkOption {
        type = with types; nullOr port;
        default = null;
        example = 2222;
        description = lib.mdDoc "Tmate server port.";
      };

      dsaFingerprint = mkOption {
        type = with types; nullOr string;
        default = null;
        example = literalExpression
          "SHA256:1111111111111111111111111111111111111111111";
        description = lib.mdDoc "Tmate server EdDSA key fingerprint.";
      };

      rsaFingerprint = mkOption {
        type = with types; nullOr string;
        default = null;
        example = literalExpression
          "SHA256:1111111111111111111111111111111111111111111";
        description = lib.mdDoc "Tmate server RSA key fingerprint.";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = lib.mdDoc ''
          Additional content written at the end of
          {file}`~/.tmate.conf`.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file.".tmate.conf".text = let
      conf =
        optional (cfg.host != null) ''set -g tmate-server-host "${cfg.host}"''
        ++ optional (cfg.port != null)
        "set -g tmate-server-port ${builtins.toString cfg.port}"
        ++ optional (cfg.dsaFingerprint != null)
        ''set -g tmate-server-ed25519-fingerprint "${cfg.dsaFingerprint}"''
        ++ optional (cfg.rsaFingerprint != null)
        ''set -g tmate-server-rsa-fingerprint "${cfg.rsaFingerprint}"''
        ++ optional (cfg.extraConfig != "") cfg.extraConfig;
    in concatStringsSep "\n" conf + "\n";
  };
}
