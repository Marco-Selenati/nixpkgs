{ lib
, stdenv
, fetchFromGitHub
, fetchzip
, writeScript
, cmake
, rocm-cmake
, rocm-runtime
, rocm-device-libs
, rocm-comgr
, rocprim
, hip
, gfortran
, git
, gtest
, boost
, python3Packages
, buildTests ? false
, buildBenchmarks ? false # Seems to depend on tests
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "rocsparse";
  version = "5.3.3";

  outputs = [
    "out"
  ] ++ lib.optionals (buildTests || buildBenchmarks) [
    "test"
  ] ++ lib.optionals buildBenchmarks [
    "benchmark"
  ];

  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocSPARSE";
    rev = "rocm-${finalAttrs.version}";
    hash = "sha256-1069oBrIpZ4M9CAkzoQ9a5j3WlCXErirTbgTUZuT6b0=";
  };

  nativeBuildInputs = [
    cmake
    rocm-cmake
    hip
    gfortran
  ];

  buildInputs = [
    rocm-runtime
    rocm-device-libs
    rocm-comgr
    rocprim
    git
  ] ++ lib.optionals (buildTests || buildBenchmarks) [
    gtest
    boost
    python3Packages.python
    python3Packages.pyyaml
  ];

  cmakeFlags = [
    "-DCMAKE_CXX_COMPILER=hipcc"
    # Manually define CMAKE_INSTALL_<DIR>
    # See: https://github.com/NixOS/nixpkgs/pull/197838
    "-DCMAKE_INSTALL_BINDIR=bin"
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
  ] ++ lib.optionals (buildTests || buildBenchmarks) [
    "-DBUILD_CLIENTS_TESTS=ON"
    "-DCMAKE_MATRICES_DIR=/build/source/matrices"
    "-Dpython=python3"
  ] ++ lib.optionals buildBenchmarks [
    "-DBUILD_CLIENTS_BENCHMARKS=ON"
  ];

  # We have to manually generate the matrices
  postPatch = lib.optionalString (buildTests || buildBenchmarks) ''
    mkdir -p matrices

    ln -s ${finalAttrs.passthru.matrices.matrix-01}/*.mtx matrices
    ln -s ${finalAttrs.passthru.matrices.matrix-02}/*.mtx matrices
    ln -s ${finalAttrs.passthru.matrices.matrix-03}/*.mtx matrices
    ln -s ${finalAttrs.passthru.matrices.matrix-04}/*.mtx matrices
    ln -s ${finalAttrs.passthru.matrices.matrix-05}/*.mtx matrices
    ln -s ${finalAttrs.passthru.matrices.matrix-06}/*.mtx matrices
    ln -s ${finalAttrs.passthru.matrices.matrix-07}/*.mtx matrices
    ln -s ${finalAttrs.passthru.matrices.matrix-08}/*.mtx matrices
    ln -s ${finalAttrs.passthru.matrices.matrix-09}/*.mtx matrices
    ln -s ${finalAttrs.passthru.matrices.matrix-10}/*.mtx matrices
    ln -s ${finalAttrs.passthru.matrices.matrix-11}/*.mtx matrices
    ln -s ${finalAttrs.passthru.matrices.matrix-12}/*.mtx matrices
    ln -s ${finalAttrs.passthru.matrices.matrix-13}/*.mtx matrices
    ln -s ${finalAttrs.passthru.matrices.matrix-14}/*.mtx matrices
    ln -s ${finalAttrs.passthru.matrices.matrix-15}/*.mtx matrices
    ln -s ${finalAttrs.passthru.matrices.matrix-16}/*.mtx matrices
    ln -s ${finalAttrs.passthru.matrices.matrix-17}/*.mtx matrices
    ln -s ${finalAttrs.passthru.matrices.matrix-18}/*.mtx matrices
    ln -s ${finalAttrs.passthru.matrices.matrix-19}/*.mtx matrices
    ln -s ${finalAttrs.passthru.matrices.matrix-20}/*.mtx matrices
    ln -s ${finalAttrs.passthru.matrices.matrix-21}/*.mtx matrices
    ln -s ${finalAttrs.passthru.matrices.matrix-22}/*.mtx matrices
    ln -s ${finalAttrs.passthru.matrices.matrix-23}/*.mtx matrices
    ln -s ${finalAttrs.passthru.matrices.matrix-24}/*.mtx matrices

    # Not used by the original cmake, causes an error
    rm matrices/*_b.mtx

    echo "deps/convert.cpp -> deps/mtx2csr"
    hipcc deps/convert.cpp -O3 -o deps/mtx2csr

    for mat in $(ls -1 matrices | cut -d "." -f 1); do
      echo "mtx2csr: $mat.mtx -> $mat.csr"
      deps/mtx2csr matrices/$mat.mtx matrices/$mat.csr
      unlink matrices/$mat.mtx
    done
  '';

  postInstall = lib.optionalString buildBenchmarks ''
    mkdir -p $benchmark/bin
    cp -a $out/bin/* $benchmark/bin
    rm $benchmark/bin/rocsparse-test
  '' + lib.optionalString (buildTests || buildBenchmarks) ''
    mkdir -p $test/bin
    mv $out/bin/* $test/bin
    rm $test/bin/rocsparse-bench || true
    mv /build/source/matrices $test
    rmdir $out/bin
  '';

  passthru = {
    matrices = import ./deps.nix {
      inherit fetchzip;
      mirror1 = "https://sparse.tamu.edu/MM";
      mirror2 = "https://www.cise.ufl.edu/research/sparse/MM";
    };

    updateScript = writeScript "update.sh" ''
      #!/usr/bin/env nix-shell
      #!nix-shell -i bash -p curl jq common-updater-scripts
      version="$(curl ''${GITHUB_TOKEN:+"-u \":$GITHUB_TOKEN\""} \
        -sL "https://api.github.com/repos/ROCmSoftwarePlatform/rocSPARSE/releases?per_page=1" | jq '.[0].tag_name | split("-") | .[1]' --raw-output)"
      update-source-version rocsparse "$version" --ignore-same-hash
    '';
  };

  meta = with lib; {
    description = "ROCm SPARSE implementation";
    homepage = "https://github.com/ROCmSoftwarePlatform/rocSPARSE";
    license = with licenses; [ mit ];
    maintainers = teams.rocm.members;
    broken = finalAttrs.version != hip.version;
  };
})
