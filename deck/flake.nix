{
  description = "Quickshell Pebbles bar for Hyprland on Steam Deck";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    quickshell = {
      url = "github:outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, quickshell }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        qs   = quickshell.packages.${system}.default;
      in
      {
        # ── development environment (nix develop) ──────────────────
        devShells.default = pkgs.mkShell {
          buildInputs = [ qs ] ++ (with pkgs; [
            hyprland

            # Fonts
            jetbrains-mono
            inter

            # Audio
            pipewire
            wireplumber
            pulseaudio

            # Network & Bluetooth
            networkmanager
            bluez
            bluez-utils

            # System utilities
            brightnessctl
            grim
            slurp

            # Optional: night light + events
            gammastep
            wlogout
            khal

            # Utilities for the install script
            curl
            git
            unzip
            jq
          ]);

          shellHook = ''
            echo "Quickshell Pebbles development environment loaded"
            echo "Run: ./install-steam-deck.sh"
          '';
        };

        # ── standalone app derivation (for reference) ──────────────
        packages.pebbles = pkgs.stdenv.mkDerivation {
          name = "quickshell-pebbles";
          version = "1.0";

          src = ./.;

          installPhase = ''
            mkdir -p $out/config/quickshell
            cp -r . $out/config/quickshell/
          '';

          meta = with pkgs.lib; {
            description = "Quickshell Pebbles bar for Hyprland";
            license = licenses.mit;
            platforms = platforms.linux;
          };
        };

        packages.default = self.packages.${system}.pebbles;
      }
    );
}
