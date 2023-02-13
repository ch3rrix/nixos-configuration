{ pkgs, ... }: {
  qt.enable = true;
  qt.platformTheme = "qt5ct";

  programs.adb.enable = true; # TODO if desktop
  users.users.default.extraGroups = [ "adbusers" ]; # TODO if desktop

  services.dbus.implementation = "broker";
  documentation.man.generateCaches = true;
}