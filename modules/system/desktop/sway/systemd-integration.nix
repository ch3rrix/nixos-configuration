{ lib, pkgs, ... }:

let
  serviceConf = {
    Slice = "session.slice";
    Restart = "always";
    RestartSec = 2;
  };
in

{
  systemd = {
    packages = with pkgs; [
      polkit-kde-agent
      foot
    ];
    user = {
      targets.sway-session = {
        description = "sway compositor session";
        documentation = [ "man:systemd.special(7)" ];
        bindsTo = [ "graphical-session.target" ];
        wants = [ "graphical-session-pre.target" ];
        after = [ "graphical-session-pre.target" ];
      };

      # activate the services from the packages
      services.plasma-polkit-agent = {
        serviceConfig = serviceConf;
        environment.PATH = lib.mkForce null; # TODO probably won't be needed in HM
        wantedBy = [ "sway-session.target" ];
      };

      services.foot-server = {
        serviceConfig = serviceConf;
        environment.PATH = lib.mkForce null; # TODO probably won't be needed in HM
        wantedBy = [ "sway-session.target" ];
      };
      sockets.foot-server.wantedBy = [ "sway-session.target" ];

      # services written by me
      services.waybar = {
        description = "Highly customizable bar for Sway";
        partOf = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        requisite = [ "graphical-session.target" ];
        script = "${pkgs.waybar}/bin/waybar";
        serviceConfig = serviceConf // {
          ExecReload = "kill -SIGUSR2 $MAINPID";
        };
        environment.PATH = lib.mkForce null; # TODO probably won't be needed in HM
        wantedBy = [ "sway-session.target" ];
      };

      services.swayidle = {
        description = "Idle management daemon";
        partOf = [ "graphical-session.target" ];
        script = "${pkgs.swayidle}/bin/swayidle -w";
        serviceConfig = serviceConf;
        environment.PATH = lib.mkForce null; # TODO probably won't be needed in HM
        wantedBy = [ "sway-session.target" ];
      };

      services.autotiling = {
        description = "Automatically alternates the container layout";
        partOf = [ "graphical-session.target" ];
        script = "${pkgs.autotiling-rs}/bin/autotiling-rs";
        serviceConfig = serviceConf;
        environment.PATH = lib.mkForce null; # TODO probably won't be needed in HM
        wantedBy = [ "sway-session.target" ];
      };

      services.wl-clip-persist = {
        description = "Keep clipboard even after programs close";
        partOf = [ "graphical-session.target" ];
        script = "${pkgs.wl-clip-persist}/bin/wl-clip-persist -c both";
        serviceConfig = serviceConf;
        environment.PATH = lib.mkForce null; # TODO probably won't be needed in HM
        wantedBy = [ "sway-session.target" ];
      };

    };
  };
}
