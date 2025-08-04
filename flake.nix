{
  description = "A flake to manage python environment";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  outputs = { nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      pkgs = system: import nixpkgs { inherit system; };
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f (pkgs system));
    in
    {
      devShells = forAllSystems (
        pkgs:
        ({
          default = pkgs.mkShell {
            buildInputs = with pkgs.python313Packages; [
              pkgs.python313
              pip
              ase
              pylint-venv
            ];
            packages = with pkgs; [
              fish
            ];
            venvDir = "./.venv";
          };
        })
      );
    };
}
