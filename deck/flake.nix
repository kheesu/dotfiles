{
  description = "Sway + Waybar for Steam Deck";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = {
          # input-leap is missing qt6.qtwayland in its nixpkgs buildInputs
          # (issue #353774), which causes a crash under Wayland. Override to add it.
          input-leap = pkgs.input-leap.overrideAttrs (old: {
            buildInputs = (old.buildInputs or []) ++ [ pkgs.qt6.qtwayland ];
          });

          # Fcitx5 bundled with Korean + Japanese engines and the GTK IM module.
          #
          # WHY a flake package and not separate `nix profile install` calls:
          # Fcitx5 discovers addons by searching lib/fcitx5/ inside its own
          # Nix store path. Engines installed as separate packages land in
          # different store paths and are never found. fcitx5-with-addons uses
          # symlinkJoin to merge all chosen packages into a single store path
          # and wraps the fcitx5 binary with FCITX_ADDON_DIRS pointing to it.
          fcitx5-input = pkgs.qt6Packages.fcitx5-with-addons.override {
            addons = with pkgs; [
              fcitx5-hangul  # Korean (Hangul)
              fcitx5-mozc    # Japanese (Mozc — larger dictionary than Anthy)
              fcitx5-gtk     # GTK2/3/4 IM module (Firefox, Nautilus, etc.)
            ];
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            swayfx
            waybar
            rofi
            foot
            nerd-fonts.jetbrains-mono
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
