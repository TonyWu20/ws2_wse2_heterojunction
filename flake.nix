{
  description = "A flake to manage python environment";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    my_lammps.url = "github:TonyWu20/lammps_flake";
  };
  outputs = { nixpkgs, my_lammps, ... }:
    let
      pkgsFor = { system, cudaSupport, overlays ? [ ] }: import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          inherit cudaSupport;
          inherit overlays;
        };
      };
    in
    {
      devShells.x86_64-linux =
        let
          pkgs = pkgsFor {
            system = "x86_64-linux";
            cudaSupport = true;
            overlays = [
              (final: prev: {
                mpi = prev.mpi.overrideAttrs {
                  configureFlags = prev.mpi.configureFlags ++ [
                    "--with-ucx=${pkgs.lib.getDev pkgs.ucx}"
                    "--with-ucx-libdir=${pkgs.lib.getLib pkgs.ucx}/lib"
                    "--enable-mca-no-build=btl-uct"
                  ];
                };
              })
            ];
          };
          lammps = my_lammps.packages.x86_64-linux.default;
          lammpsKlt = lammps.override {
            gpuArch = "sm_90";
            kokkosGpuArch = "hopper90";
          };
          buildInputs = with pkgs.python313Packages; [
            pkgs.python313
            pip
            ase
            pylint-venv
            pkgs.cudaPackages.cudatoolkit
          ];
          packages = with pkgs; [
            fish
            pkgs.python313Packages.jupyter
          ];
        in
        {
          default = pkgs.mkShell {
            inherit buildInputs;
            packages = packages ++ [
              lammps
            ];
            venvDir = "./.venv";
          };
          arch = pkgs.mkShell {
            inherit buildInputs;
            packages = packages ++ [
              lammps
            ];
            shellHook = ''
              export LD_PRELOAD=/usr/lib/libcuda.so.1
            '';
          };
          klt = pkgs.mkShell {
            inherit buildInputs;
            packages = packages ++ [
              lammpsKlt
            ];
            venvDir = "./.venv";
            shellHook = ''
              export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libcuda.so.1
            '';
          };
        };
      devShells.aarch64-darwin =
        let
          pkgs = pkgsFor { system = "aarch64-darwin"; cudaSupport = false; };
          lammpsMac = my_lammps.packages.aarch64-darwin.default;
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs.python313Packages; [
              pkgs.python313
              pip
              ase
              pylint-venv
            ];
            packages = with pkgs; [
              fish
              lammpsMac
              pkgs.python313Packages.jupyter
            ];
            venvDir = "./.venv";
          };
        };
    };
}
