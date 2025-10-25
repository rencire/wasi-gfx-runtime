{
  description = "A basic flake for rust development";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flakelight.url = "github:accelbread/flakelight";
  # For nightly rust
  inputs.fenix = {
    url = "github:nix-community/fenix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # For incremental crate builds and caching during development
  inputs.crane.url = "github:ipetkov/crane";

  outputs =
    {
      flakelight,
      fenix,
      crane,
      ...
    }@inputs:
    flakelight ./. {
      inherit inputs;
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      withOverlays = [ fenix.overlays.default ];
      packages = {
        witDepsCli =
          { pkgs, ... }:
          let
            rustToolchain = (
              fenix.packages.${pkgs.system}.minimal.withComponents [
                "cargo"
                "rustc"
              ]
            );
            craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;
          in
          craneLib.buildPackage {
            pname = "wit-deps-cli";
            version = "0.5.0";
            src = pkgs.fetchCrate {
              pname = "wit-deps-cli";
              version = "0.5.0";
              hash = "sha256-GkQJcGk3qU+ZKoaFO2rSwlaSDpd517gmxwgb8Rt5RSk=";
            };
          };
      };
      # # Expose as runnable app
      # # Notes: We can grab my-app package from `pkgs` here, because flakelight automatically added it to
      # # overlays.default.  Even for default package, it seems to grab the name from `pname`?
      # apps = {
      #   default =
      #     { my-app, ... }:
      #     {
      #       type = "app";
      #       program = "${my-app}/bin/my-app";
      #     };
      # };
      devShell = pkgs: {
        packages =
          let
            rustToolchain = (
              with fenix.packages.${pkgs.system};
              combine [
                complete."cargo"
                complete."clippy"
                complete."rust-src"
                complete."rustc"
                complete."rustfmt"
                targets.wasm32-unknown-unknown.latest.rust-std
              ]
            );
          in
          [
            rustToolchain
            pkgs.rust-analyzer-nightly
            pkgs.wasm-tools
            pkgs.witDepsCli
          ];
      };
    };
}
