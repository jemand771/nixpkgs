{
  cargo,
  fetchFromGitHub,
  fetchYarnDeps,
  lib,
  rustPlatform,
  stdenv,
  typescript,
  openapi-generator-cli,
  yarnConfigHook,
  yarnBuildHook,
  nodejs,
}:
let
  version = "0.10.1";
  src = fetchFromGitHub {
    owner = "warp-tech";
    repo = "warpgate";
    rev = "refs/tags/v${version}";
    hash = "sha256-FUEfrofRLxyUH/cq8HaivfNe1wb2NmaQixXORnNIlL8=";
  };
  sourceRoot = "${src.name}/warpgate-web";
  schema = stdenv.mkDerivation {
    inherit src;
    pname = "warpgate-schema";
    inherit version;

    cargoDeps = rustPlatform.fetchCargoTarball {
      inherit src;
      cargoRoot = "${sourceRoot}";
      hash = "sha256-enPiW8An2nXB+fbLz5U4fhWuJaDEWblXyKeVnUaoV8o=";
    };

    nativeBuildInputs = [
      cargo
      rustPlatform.cargoSetupHook
      openapi-generator-cli
      typescript
    ];
    RUSTC_BOOTSTRAP = 1;
    RUSTFLAGS = [ "--cfg tokio_unstable" ];

    # see openapi:* scripts in https://github.com/warp-tech/warpgate/blob/main/warpgate-web/package.json
    buildPhase = ''
      runHook preBuild
      cd warpgate-web
      mkdir dist

      generate_schema () {
        mkdir -p $out/src/$1/lib
        cargo run -p $2 > $out/src/$1/lib/openapi-schema.json
        openapi-generator-cli generate \
          -g typescript-fetch \
          -i $out/src/$1/lib/openapi-schema.json \
          -o $out/src/$1/lib/api-client \
          -p npmName=warpgate-$1-api-client \
          -p useSingleRequestParameter=true
        pushd $out/src/$1/lib/api-client
        tsc --target esnext --module esnext
        rm -r README.md tsconfig.json src
        popd
      }

      generate_schema gateway warpgate-protocol-http
      generate_schema admin warpgate-admin
      runHook postBuild
    '';
  };

  frontend = stdenv.mkDerivation rec {
    inherit src version sourceRoot;
    pname = "warpgate-web";

    yarnOfflineCache = fetchYarnDeps {
      inherit src version sourceRoot;
      hash = "sha256-uuGf4Zg6T3HLlW74/ud/FfmUAOo6vWQVZLAq3Tq3Wv8=";
    };

    postUnpack = "cp -r ${schema}/src ${sourceRoot}";
    nativeBuildInputs = [
      schema
      yarnConfigHook
      yarnBuildHook
      nodejs
    ];
    # TODO can yarnInstallHook help here? (https://github.com/NixOS/nixpkgs/pull/328544)
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r dist $out
      runHook postInstall
    '';
  };
in
rustPlatform.buildRustPackage rec {
  pname = "warpgate";
  inherit src version;

  postUnpack = "cp -r ${frontend}/dist ${sourceRoot}";
  nativeBuildInputs = [ frontend ];

  RUSTC_BOOTSTRAP = 1;
  RUSTFLAGS = [ "--cfg tokio_unstable" ];
  cargoHash = "sha256-YU27ZaO5C+MoKHW2VnbAE5Bef0tZbm0VV1HApiuaDhw=";

  cargoTestFlags = [ "--workspace" ];

  meta = {
    description = "Smart SSH, HTTPS and MySQL bastion that requires no additional client-side software";
    mainProgram = "warpgate";
    homepage = "https://github.com/warp-tech/warpgate/";
    changelog = "https://github.com/warp-tech/warpgate/releases/tag/v${version}";
    license = lib.licenses.asl20;
    # TODO lib.maintainers.jemand771 after https://github.com/NixOS/nixpkgs/pull/328036
    maintainers = [ ];
  };
}
