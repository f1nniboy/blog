{ pkgs, domain, ... }:
let
  configFile = import ./config.nix {
    inherit pkgs domain;
  };
in
pkgs.stdenv.mkDerivation {
  name = "blog";
  src = ./src;

  nativeBuildInputs = with pkgs; [
    coreutils
    zola
    sass
  ];

  configurePhase = ''
    mkdir -p themes sass
    cp -r "${./theme}" themes/custom
  '';

  buildPhase = ''
    zola -c ${configFile} build
  '';

  installPhase = ''
    cp -r public "$out"

    # generate .etag files for cache
    for file in $(find "$out" -type f); do
        hash="$(md5sum "$file" | cut -d" " -f1)"
        echo "\"$hash\"" > "$file.etag"
    done
  '';
}
