lib: with lib;
rec {
  # Package system
  forAllSystems = genAttrs systems.flakeExposed;

  unfreePkgs = nixpkgs: overlay: system:
    import nixpkgs {
      inherit system;
      overlays = singleton overlay;
      config.allowUnfree = true;
    };

  mkOverlays = dir: inputs:
    mapAttrs'
      (name: _:
        nameValuePair (removeSuffix ".nix" name) (import /${dir}/${name} inputs))
      (filtredReadDir dir);

  trimShebang = script:
    lib.concatLines
      (lib.filter
        (line: line != "" && !(lib.hasPrefix "#!" line))
        (lib.splitString "\n" script));

  # Module system
  filtredReadDir = dir:
    filterAttrs
      (name: type: type == "directory" || hasSuffix ".nix" name)
      (builtins.readDir dir);

  mkAttrsTree = dir:
    mapAttrs'
      (name: type:
        if type == "directory"
        then nameValuePair name (mkAttrsTree /${dir}/${name})
        else nameValuePair (removeSuffix ".nix" name) /${dir}/${name})
      (filtredReadDir dir);

  mkModules = dir:
    let
      listOfPaths = dir: flatten (mapAttrsToList
        (name: type:
          if type == "directory"
          then [ /${dir}/${name + "Tree"} (listOfPaths /${dir}/${name}) ]
          else /${dir}/${name})
        (filtredReadDir dir));
    in
    listToAttrs
      (forEach (listOfPaths dir)
        (path:
          if ! hasSuffix "Tree" (baseNameOf path) then
            if baseNameOf path == "default.nix"
            then nameValuePair (baseNameOf (dirOf path)) path
            else nameValuePair (removeSuffix ".nix" (baseNameOf path)) path
          else
            nameValuePair
              (baseNameOf path)
              (mkAttrsTree /${dirOf path}/${removeSuffix "Tree" (baseNameOf path)})
        ));

  expandTrees = modules:
    let
      f = mod:
        if isAttrs mod
        then forEach (attrValues mod) f
        else mod;
    in
    flatten (forEach modules f);

  # Hosts system TODO
  mkHosts = dir: inputs:
    genAttrs
      (attrNames (builtins.readDir dir))
      (name:
        nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs expandTrees;
            inherit (inputs.self) nixosModules;
          };
          modules = [ /${dir}/${name} { networking.hostName = name; } ] ++
            filter (val: isPath val) (attrValues inputs.self.nixosModules);
        });

  hostsAsPkgs = cfgs:
    foldAttrs
      (x: y: x // y)
      { }
      (concatLists
        (forEach
          (attrNames cfgs)
          (name:
            with cfgs.${name};
            if name == "liveCD"
            then [{ ${pkgs.system}.${name} = config.system.build.isoImage; }]
            else [{ ${pkgs.system}.${name} = config.system.build.toplevel; }])
        )
      );
}
