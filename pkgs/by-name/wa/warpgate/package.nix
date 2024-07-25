{
  cargo,
  fetchFromGitHub,
  fetchYarnDeps,
  lib,
  mkYarnPackage,
  rustPlatform,
  stdenv,
  typescript,
  openapi-generator-cli,
  fetchpatch,
  yarnConfigHook,
  yarnBuildHook,
  nodejs,
}:
let
  version = "0.10.0";
  src = fetchFromGitHub {
    owner = "warp-tech";
    repo = "warpgate";
    rev = "refs/tags/v${version}";
    hash = "sha256-VU5nxY0iqP1bFhKtQUCj1OXSmEuAIuWlHTmaUuIZiu0=";
  };
  patches = [
    (fetchpatch {
      url = "https://github.com/warp-tech/warpgate/commit/e9b4a3b94fd6b26ffa4f457a8cb7d68581984078.patch";
      hash = "sha256-fsVlEPEWSqX493lTwRzcC7Dxc0LZIAX+8WWlUQ1rdAw=";
    })
  ];
  patchFlags = [ "-p2" ];
  schema = stdenv.mkDerivation {
    inherit src;
    pname = "warpgate-schema";
    inherit version;

    cargoDeps = rustPlatform.fetchCargoTarball {
      inherit src;
      cargoRoot = "${src}/warpgate-web";
      hash = "sha256-hJpFbWvwTpw0k3BWFBf4/XWHbs/LS7OCgKewgpPjNI4=";
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
    '';
  };

  frontend = stdenv.mkDerivation rec {
    inherit src version;
    inherit patches patchFlags;
    pname = "warpgate-web";

    sourceRoot = "${src.name}/warpgate-web";
    yarnOfflineCache = fetchYarnDeps {
      inherit src version;
      inherit patches patchFlags;
      sourceRoot = "${src.name}/warpgate-web";
      hash = "sha256-uuGf4Zg6T3HLlW74/ud/FfmUAOo6vWQVZLAq3Tq3Wv8=";
    };

    postUnpack = "cp -r ${schema}/src ${sourceRoot}";
    nativeBuildInputs = [
      schema
      yarnConfigHook
      yarnBuildHook
      nodejs
    ];
    # TODO why do I have to mkdir $out ?
    installPhase = ''
      runHook preInstall
      mkdir -p $out && cp -r dist $out
      runHook postInstall
    '';
    doDist = false;
  };
in
rustPlatform.buildRustPackage rec {
  pname = "warpgate";
  inherit src version;

  postUnpack = "cp -r ${frontend}/dist ${src.name}/warpgate-web";
  nativeBuildInputs = [ frontend ];

  RUSTC_BOOTSTRAP = 1;
  RUSTFLAGS = [ "--cfg tokio_unstable" ];
  cargoHash = "sha256-eaQir7Xu3quybGLUOnY49Bhm+7/n+97Uxni51dvm+1M=";

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
