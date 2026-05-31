{
  description = "Sway + Waybar for Steam Deck";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixgl.url = "github:nix-community/nixGL";
  };

  outputs = { self, nixpkgs, flake-utils, nixgl }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            sway
            waybar
            rofi-wayland
            foot
            nerdfonts
            brightnessctl
            grim
            slurp
            wl-clipboard
          ];

          shellHook = ''
            echo "Sway + Waybar Steam Deck environment loaded"
            echo "Run: ./install-steam-deck.sh"
          '';
        };
      }
    );
}
