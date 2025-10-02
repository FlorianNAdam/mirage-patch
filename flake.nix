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

            if [ "$EUID" -ne 0 ]; then
              echo "error: this script must be run as root" >&2
              exit 1
            fi
            if [ "$#" -ne 1 ]; then
              echo "Usage: $0 <path-to-file>"
              exit 1
            fi
            FILE="$1"
            if [ ! -f "$FILE" ]; then
              echo "File '$FILE' does not exist"
              exit 1
            fi

            # Create Tempfile
            filename="''${FILE##*/}"
            temp_dir=$(mktemp -d /tmp/mirage-patch.XXXXXX)
            temp_file="$temp_dir/$filename"
            cp -- "$FILE" "$temp_file"
            chown "$SUDO_USER" "$temp_dir"
            chown "$SUDO_USER" "$temp_file"
            chmod 600 "$temp_file"

            # Start mirage in background
            ${
              mirage.defaultPackage.${pkgs.system}
            }/bin/mirage --exec "cat $temp_file" --allow-other "$FILE" > /dev/null 2>&1 &
            mirage_pid=$!

            # Run editor as the original user using su -l
            su -l "$SUDO_USER" -c '"''${EDITOR:-nano}" '"$temp_file"

            # Kill background mirage process
            kill "$mirage_pid" 2>/dev/null || true
            wait "$mirage_pid" 2>/dev/null || true

            rm -f "$temp_dir"
          '';

          default = mirage-patch;
        };
      }
    );
}
