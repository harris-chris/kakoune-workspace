{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
    get-workspace-name.url = github:harris-chris/get-workspace-name;
  };
  outputs = { self, nixpkgs, get-workspace-name }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ get-workspace-name.overlays.default ];
      };
      script = ''
        #! ${pkgs.bash}/bin/bash
        desktop="$(${pkgs.getworkspacename}/bin/getworkspacename)"
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
      getPackage = pkgs: pkgs.writeShellApplication {
          name = "kk";
          text = script;
        };
    in {
      packages.${system}.default = getPackage pkgs;
      overlays.default = final: prev: {
        kakoune-workspace = getPackage final;
      };
    };
}
