{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.msmtp;

  msmtpAccounts =
    filter (a: a.msmtp.enable) (attrValues config.accounts.email.accounts);

  onOff = p: if p then "on" else "off";

  accountStr = account:
    with account;
    concatStringsSep "\n" ([ "account ${name}" ]
      ++ mapAttrsToList (n: v: n + " " + v) ({
        host = smtp.host;
        from = address;
        auth = "on";
        user = userName;
        tls = onOff smtp.tls.enable;
        tls_starttls = onOff smtp.tls.useStartTls;
      } // optionalAttrs (msmtp.tls.fingerprint != null) {
        tls_fingerprint = msmtp.tls.fingerprint;
      } // optionalAttrs (smtp.port != null) { port = toString smtp.port; }
        // optionalAttrs (smtp.tls.certificatesFile != null) {
          tls_trust_file = smtp.tls.certificatesFile;
        } // optionalAttrs (passwordCommand != null) {
          passwordeval = toString passwordCommand;
        } // msmtp.extraConfig) ++ optional primary "account default : ${name}"
      ++ map (alias: ''

        account ${alias} : ${name}
        from ${alias}
      '') aliases);

  configFile = mailAccounts: ''
    # Generated by Home Manager.

    ${cfg.extraConfig}

    ${concatStringsSep "\n\n" (map accountStr mailAccounts)}

    ${cfg.extraAccounts}
  '';

in {

  options = {
    programs.msmtp = {
      enable = mkEnableOption (lib.mdDoc "msmtp");

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = lib.mdDoc ''
          Extra configuration lines to add to {file}`~/.msmtprc`.
          See <https://marlam.de/msmtp/msmtprc.txt> for examples.

          Note, if running msmtp fails with the error message "account default
          was already defined" then you probably have an account command here.
          Account commands should be placed in
          [](#opt-accounts.email.accounts._name_.msmtp.extraConfig).
        '';
      };

      extraAccounts = mkOption {
        type = types.lines;
        default = "";
        description = lib.mdDoc ''
          Extra configuration lines to add to the end of {file}`~/.msmtprc`.
          See <https://marlam.de/msmtp/msmtprc.txt> for examples.
        '';
      };
    };

    accounts.email.accounts = mkOption {
      type = with types; attrsOf (submodule (import ./msmtp-accounts.nix));
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.msmtp ];

    xdg.configFile."msmtp/config".text = configFile msmtpAccounts;

    home.sessionVariables = {
      MSMTP_QUEUE = "${config.xdg.dataHome}/msmtp/queue";
      MSMTP_LOG = "${config.xdg.dataHome}/msmtp/queue.log";
    };
  };
}
