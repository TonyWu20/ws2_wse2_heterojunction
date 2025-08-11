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
          pkgs = pkgsFor { system = "x86_64-linux"; cudaSupport = true; };
          gpuOptions = cudaArch: [
            "GPU_ARCH=${cudaArch}"
            "GPU_API=CUDA"
            "CUDA_MPS_SUPPORT=on"
          ];
          setKokkosOptions = kokkosCudaArch: with pkgs.lib;[
            (cmakeBool "Kokkos_ENABLE_OPENMP" true)
            (cmakeBool "Kokkos_ENABLE_CUDA" true)
            (cmakeBool "Kokkos_ARCH_${strings.toUpper kokkosCudaArch}" true)
            (cmakeBool "Kokkos_ARCH_NATIVE" true)
          ];
          lammps = my_lammps.packages.x86_64-linux.default;
          lammpsKlt = my_lammps.packages.x86_64-linux.sm_90;
          buildInputs = with pkgs.python313Packages; [
            pkgs.python313
            pip
            ase
            pylint-venv
            pkgs.cudaPackages.cudatoolkit
          ];
          packages = with pkgs; [
            fish
            mpi
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
          gpuExtraOptions = [
            "GPU_API=opencl"
          ];
          kokkosOptions = with pkgs.lib; [
            (cmakeBool "Kokkos_ENABLE_OPENMP" true)
            (cmakeBool "Kokkos_ARCH_NATIVE" true)
          ];
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
              mpi
              lammpsMac
            ];
            venvDir = "./.venv";
          };
        };
    };
}
