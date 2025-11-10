{
  description = "My blog";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";

    theme = {
      # commit without the theme switcher (to avoid js)
      url = "github:ebkalderon/terminus/d401cd0dc8464f16f602a286797f9d99c0b9eb44";
      flake = false;
    };
  };

  outputs =
    {
      systems,
      nixpkgs,
      ...
    }@inputs:
    let
      eachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      packages = eachSystem (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
        in
        {
          default = import ./package.nix {
            inherit inputs pkgs;
          };
        }
      );
    };
}
