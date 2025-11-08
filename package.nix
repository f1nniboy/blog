{ inputs, pkgs, ... }:
let
  configFile = import ./config.nix {
    inherit pkgs;
  };
in
pkgs.stdenv.mkDerivation {
  name = "blog";
  src = ./src;

  nativeBuildInputs = with pkgs; [
    zola
    sass
  ];

  configurePhase = ''
    mkdir -p themes sass
    cp -r ${inputs.theme}/ themes/custom
  '';

  buildPhase = ''
    zola -c ${configFile} build
  '';

  installPhase = ''
    cp -r public $out
  '';
}
