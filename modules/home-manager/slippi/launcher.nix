slippiClosure: {
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types mkIf;
  cfg = config.slippi-launcher;
  slippi-packages = slippiClosure pkgs.system;
  netplay-package = version: hash:
    slippi-packages.netplay.overrideAttrs {
      inherit version hash;
    };
  playback-package = version: hash:
    slippi-packages.playback.overrideAttrs {
      inherit version hash;
    };
in {
  # defaults here are true since we assume if you're importing the module, you
  # want it on ;)
  options.slippi-launcher = {
    enable = mkEnableOption "Install Slippi Launcher" // {default = true;};

    netplayVersion = mkOption {
      default = null;
      type = types.nullOr types.str;
      description = "The version of Slippi Netplay to install. Will fallback to the defaults for the package if left null.";
    };
    netplayHash = mkOption {
      default = null;
      type = types.nullOr types.str;
      description = "The hash of the Slippi Netplay zip to install. Will fallback to the defaults for the package if left null.";
    };

    playbackVersion = mkOption {
      default = null;
      type = types.nullOr types.str;
      description = "The version of Slippi Playback to install. Will fallback to the defaults for the package if left null.";
    };
    playbackHash = mkOption {
      default = null;
      type = types.nullOr types.str;
      description = "The hash of the Slippi Playback zip to install. Will fallback to the defaults for the package if left null.";
    };

    isoPath = mkOption {
      default = "";
      type = types.str;
      description = "The path to an NTSC Melee ISO.";
    };

    launchMeleeOnPlay = mkEnableOption "Launch Melee in Dolphin when the Play button is pressed." // {default = true;};

    enableJukebox = mkEnableOption "Enable in-game music via Slippi Jukebox. Incompatible with WASAPI." // {default = true;};

    rootSlpPath = mkOption {
      default = "${config.home.homeDirectory}/Slippi";
      type = types.str;
      description = "The folder where your SLP replays should be saved.";
    };

    useMonthlySubfolders = mkEnableOption "Save replays to monthly subfolders";

    spectateSlpPath = mkOption {
      default = "${cfg.rootSlpPath}/Spectate";
      type = types.nullOr types.str;
      description = "The folder where spectated games should be saved.";
    };

    extraSlpPaths = mkOption {
      default = [];
      type = types.listOf types.str;
      description = "Choose any additional SLP directories that should show up in the replay browser.";
    };
  };
  config = let
    cfgNetplayPackage = netplay-package cfg.netplayVersion cfg.netplayHash;
    cfgPlaybackPackage = playback-package cfg.playbackVersion cfg.playbackHash;
  in {
    home.packages = [(mkIf cfg.enable slippi-packages.launcher)];
    home.file.".config/Slippi Launcher/netplay/Slippi_Online-x86_64.AppImage" = {
      enable = cfg.enable;
      source = "${cfgNetplayPackage}/bin/Slippi_Online-x86_64.AppImage";
      recursive = false;
    };
    home.file.".config/Slippi Launcher/netplay/Sys" = {
      enable = cfg.enable;
      source = "${pkgs.fetchzip {
        url = "https://github.com/project-slippi/Ishiiruka/releases/download/v${cfg.netplayVersion}/FM-Slippi-${cfg.netplayVersion}-Linux.zip";
        hash = cfg.netplayHash;
        stripRoot = false;
      }}/Sys";
      recursive = false;
    };
    home.file.".config/Slippi Launcher/playback/Slippi_Playback-x86_64.AppImage" = {
      enable = cfg.enable;
      source = "${cfgPlaybackPackage}/bin/Slippi_Playback-x86_64.AppImage";
      recursive = false;
    };
    home.file.".config/Slippi Launcher/playback/Sys" = {
      enable = cfg.enable;
      source = "${
        pkgs.fetchzip {
          url = "https://github.com/project-slippi/Ishiiruka-Playback/releases/download/v${cfg.playbackVersion}/playback-${cfg.playbackVersion}-Linux.zip";
          hash = cfg.netplayHash;
          stripRoot = false;
        }
      }/Sys";
      recursive = false;
    };
    xdg.configFile."Slippi Launcher/Settings" = {
      enable = cfg.enable;
      source = let
        jsonFormat = pkgs.formats.json {};
      in
        jsonFormat.generate "slippi-config" {
          settings = {
            isoPath = cfg.isoPath;

            launchMeleeOnPlay = cfg.launchMeleeOnPlay;
            enableJukebox = cfg.enableJukebox;

            rootSlpPath = cfg.rootSlpPath;
            useMonthlySubfolders = cfg.useMonthlySubfolders;
            spectateSlpPath = cfg.spectateSlpPath;
            extraSlpPaths = cfg.extraSlpPaths;

            netplayDolphinPath = "${cfgNetplayPackage}/bin/";
            playbackDolphinPath = "${cfgPlaybackPackage}/bin/";

            autoUpdateLauncher = false;
          };
        };
    };
  };
}
