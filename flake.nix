{
  description = "My blog";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";

    theme = {
      url = "github:ebkalderon/terminus";
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
