{
  description = "A flake to manage python environment";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    my_lammps.url = "github:TonyWu20/lammps_flake";
  };
  outputs = { nixpkgs, my_lammps, ... }:
    let
      pkgsFor = { system, cudaSupport }: import nixpkgs {
        inherit system; overlays = [ my_lammps.overlays.default ];
        config = {
          allowUnfree = true;
          inherit cudaSupport;
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
          lammps = { cudaArch, kokkosCudaArch }: my_lammps.lammps {
            gpuExtraOptions = gpuOptions cudaArch;
            kokkosOptios = setKokkosOptions kokkosCudaArch;
            inherit pkgs;
          };
          buildInputs = with pkgs.python313Packages; [
            pkgs.python313
            pip
            ase
            pylint-venv
            pkgs.cudaPackages.cudatoolkit
          ];
        in
        {
          default = pkgs.mkShell {
            inherit buildInputs;
            packages = with pkgs; [
              fish
              mpi
              (lammps
                { cudaArch = "sm_61"; kokkosCudaArch = "pascal61"; })
            ];
            venvDir = "./.venv";
          };
          klt = pkgs.mkShell {
            inherit buildInputs;
            packages = with pkgs; [
              fish
              mpi
              (lammps
                { cudaArch = "sm_90"; kokkosCudaArch = "hopper90"; })
            ];
            venvDir = "./.venv";
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
