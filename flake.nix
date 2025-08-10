{
  description = "A flake to manage python environment";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    my_lammps.url = "github:TonyWu20/lammps_flake";
  };
  outputs = { nixpkgs, my_lammps, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      pkgs = system: import nixpkgs {
        inherit system; overlays = [ my_lammps.overlays.default ];
        config = {
          allowUnfree = true;
          cudaSupport = true;
        };
      };
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
            ] ++ (
              pkgs.lib.optional pkgs.stdenv.isLinux [
                pkgs.cudaPackages.cudatoolkit
              ]
            );
            packages = with pkgs; [
              fish
              mpi
              lammps
            ];
            venvDir = "./.venv";
          };
        })
      );
    };
}
