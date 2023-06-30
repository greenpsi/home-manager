{ config, lib, ... }:

with lib;

let

  extraConfigType = with lib.types;
    attrsOf (oneOf [ str int bool (listOf str) ]);

  perAccountGroups = { name, config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        # Make value of name the same as the name used with the dot prefix
        default = name;
        readOnly = true;
        description = lib.mdDoc ''
          The name of this group for this account. These names are different than
          some others, because they will hide channel names that are the same.
        '';
      };

      channels = mkOption {
        type = types.attrsOf (types.submodule channel);
        default = { };
        description = lib.mdDoc ''
          List of channels that should be grouped together into this group. When
          performing a synchronization, the groups are synchronized, rather than
          the individual channels.

          Using these channels and then grouping them together allows for you to
          define the maildir hierarchy as you see fit.
        '';
      };
    };
  };

  # Options for configuring channel(s) that will be composed together into a group.
  channel = { name, config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        default = name;
        readOnly = true;
        description = lib.mdDoc ''
          The unique name for THIS channel in THIS group. The group will refer to
          this channel by this name.

          In addition, you can manually sync just this channel by specifying this
          name to mbsync on the command line.
        '';
      };

      farPattern = mkOption {
        type = types.str;
        default = "";
        example = "[Gmail]/Sent Mail";
        description = lib.mdDoc ''
          IMAP4 patterns for which mailboxes on the remote mail server to sync.
          If `Patterns` are specified, `farPattern`
          is interpreted as a prefix which is not matched against the patterns,
          and is not affected by mailbox list overrides.

          If this is left as the default, then mbsync will default to the pattern
          `INBOX`.
        '';
      };

      nearPattern = mkOption {
        type = types.str;
        default = "";
        example = "Sent";
        description = lib.mdDoc ''
          Name for where mail coming from the remote (far) mail server will end up
          locally. The mailbox specified by the far pattern will be placed in
          this directory.

          If this is left as the default, then mbsync will default to the pattern
          `INBOX`.
        '';
      };

      patterns = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "INBOX" ];
        description = lib.mdDoc ''
          Instead of synchronizing *just* the mailboxes that
          match the `farPattern`, use it as a prefix which is
          not matched against the patterns, and is not affected by mailbox list
          overrides.
        '';
      };

      extraConfig = mkOption {
        type = extraConfigType;
        default = { };
        example = literalExpression ''
          {
            Create = "both";
            CopyArrivalDate = "yes";
            MaxMessages = 10000;
            MaxSize = "1m";
          }
        '';
        description = lib.mdDoc ''
          Extra configuration lines to add to *THIS* channel's
          configuration.
        '';
      };
    };
  };

in {
  options.mbsync = {
    enable = mkEnableOption (lib.mdDoc "synchronization using mbsync");

    flatten = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = ".";
      description = lib.mdDoc ''
        If set, flattens the hierarchy within the maildir by
        substituting the canonical hierarchy delimiter
        `/` with this value.
      '';
    };

    subFolders = mkOption {
      type = types.enum [ "Verbatim" "Maildir++" "Legacy" ];
      default = "Verbatim";
      example = "Maildir++";
      description = lib.mdDoc ''
        The on-disk folder naming style. This option has no
        effect when {option}`flatten` is used.
      '';
    };

    create = mkOption {
      type = types.enum [ "none" "maildir" "imap" "both" ];
      default = "none";
      example = "maildir";
      description = lib.mdDoc ''
        Automatically create missing mailboxes within the
        given mail store.
      '';
    };

    remove = mkOption {
      type = types.enum [ "none" "maildir" "imap" "both" ];
      default = "none";
      example = "imap";
      description = lib.mdDoc ''
        Propagate mailbox deletions to the given mail store.
      '';
    };

    expunge = mkOption {
      type = types.enum [ "none" "maildir" "imap" "both" ];
      default = "none";
      example = "both";
      description = lib.mdDoc ''
        Permanently remove messages marked for deletion from
        the given mail store.
      '';
    };

    patterns = mkOption {
      type = types.listOf types.str;
      default = [ "*" ];
      description = lib.mdDoc ''
        Pattern of mailboxes to synchronize.
      '';
    };

    groups = mkOption {
      type = types.attrsOf (types.submodule perAccountGroups);
      default = { };
      # The default cannot actually be empty, but contains an attribute set where
      # the channels set is empty. If a group is specified, then a name is given,
      # creating the attribute set.
      description = lib.mdDoc ''
        Some email providers (Gmail) have a different directory hierarchy for
        synchronized email messages. Namely, when using mbsync without specifying
        a set of channels into a group, all synchronized directories end up beneath
        the `[Gmail]/` directory.

        This option allows you to specify a group, and subsequently channels that
        will allow you to sync your mail into an arbitrary hierarchy.
      '';
    };

    extraConfig.channel = mkOption {
      type = extraConfigType;
      default = { };
      example = literalExpression ''
        {
          MaxMessages = 10000;
          MaxSize = "1m";
        };
      '';
      description = lib.mdDoc ''
        Per channel extra configuration.
      '';
    };

    extraConfig.local = mkOption {
      type = extraConfigType;
      default = { };
      description = lib.mdDoc ''
        Local store extra configuration.
      '';
    };

    extraConfig.remote = mkOption {
      type = extraConfigType;
      default = { };
      description = lib.mdDoc ''
        Remote store extra configuration.
      '';
    };

    extraConfig.account = mkOption {
      type = extraConfigType;
      default = { };
      example = literalExpression ''
        {
          PipelineDepth = 10;
          Timeout = 60;
        };
      '';
      description = lib.mdDoc ''
        Account section extra configuration.
      '';
    };
  };
}
