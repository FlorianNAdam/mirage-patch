{
  description = "Simple application for temporarily patching immutable files at runtime for testing purposes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    mirage = {
      url = "github:FlorianNAdam/mirage";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      mirage,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages = rec {
          mirage-patch = pkgs.writeShellScriptBin "mirage-patch" ''
            set -e

            if [ "$#" -ne 1 ]; then
              echo "Usage: $0 <path-to-file>"
              exit 1
            fi
            FILE="$1"
            if [ ! -f "$FILE" ]; then
              echo "File '$FILE' does not exist"
              exit 1
            fi

            temp_file=$(mktemp /tmp/tempfile.XXXXXX)
            cp -- "$FILE" "$temp_file"

            sudo true
            sudo ${
              mirage.defaultPackage.${pkgs.system}
            }/bin/mirage --exec "cat $temp_file" --allow-other "$FILE" > /dev/null 2>&1 &
            mirage_pid=$!

            "''${EDITOR:-nano}" "$temp_file"

            sudo kill "$mirage_pid" 2>/dev/null
            wait "$mirage_pid" 2>/dev/null

            rm -f "$temp_file"
          '';

          default = mirage-patch;
        };
      }
    );
}
