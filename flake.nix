{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-21.11;
    flake-utils.url = github:numtide/flake-utils;
    get-workspace-name.url = github:harris-chris/get-workspace-name;
  };
  outputs = { self, nixpkgs, flake-utils, get-workspace-name }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        getworkspacename = get-workspace-name.defaultPackage.${system};
        script = ''
          #! ${pkgs.bash}/bin/bash
          desktop="$(${getworkspacename}/bin/getworkspacename)"
          kakprofile=$(which kak)
          kakoune=$(readlink -f "$kakprofile")
          if [[ -z "$kakoune" ]]; then
            echo "Could not find kakoune installed"
            exit 1
          fi
          # bspc result was empty, so most likely not using bspwm
          [ -z "$desktop" ] && exec $kakoune "$@"
          $kakoune -clear
          # if session with desktop id is found, connect to it. otherwise create it
          if $kakoune -l | grep -q "^''${desktop}$"; then
              exec $kakoune -c "$desktop" "$@"
          else
              exec $kakoune -s "$desktop" "$@"
          fi
        '';
        kakoune-workspace = pkgs.writeShellApplication {
          name = "kk";
          text = script;
        };
      in rec {
        defaultPackage = kakoune-workspace;
        devShell = pkgs.mkShell {
          buildInputs = [
            getworkspacename
            defaultPackage
          ];
        };
      });
}
