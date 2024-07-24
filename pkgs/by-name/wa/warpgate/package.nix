{ cargo
, fetchFromGitHub
, fetchYarnDeps
, lib
, mkYarnPackage
, rustPlatform
, stdenv
, typescript
, openapi-generator-cli
}:
let
  version = "0.10.0";
  src = fetchFromGitHub {
    # owner = "warp-tech";
    owner = "jemand771";
    repo = "warpgate";
    # rev = "v${version}";
    rev = "update-lockfile";
    # hash = "sha256-VU5nxY0iqP1bFhKtQUCj1OXSmEuAIuWlHTmaUuIZiu0=";
    hash = "sha256-14FzghqgN432O2R6rsnzsBQYXgdrOh4pWfwd5qppbLI=";
  };
  schema = stdenv.mkDerivation {
    inherit src;
    pname = "warpgate-schema";
    inherit version;

    cargoDeps = rustPlatform.fetchCargoTarball {
      inherit src;
      cargoRoot = "${src}/warpgate-web";
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

  frontend = mkYarnPackage {
    src = "${src}/warpgate-web";
    pname = "warpgate-web";
    inherit version;

    yarnLock = "${src}/warpgate-web/yarn.lock";
    yarnOfflineCache = fetchYarnDeps {
      yarnLock = "${src}/warpgate-web/yarn.lock";
      hash = "sha256-uuGf4Zg6T3HLlW74/ud/FfmUAOo6vWQVZLAq3Tq3Wv8=";
    };

    # vite wants writable node_modules
    configurePhase = ''
      cp -r $node_modules node_modules
      chmod +w node_modules
      cp -r ${schema}/src .
    '';
    nativeBuildInputs = [ schema ];
    buildPhase = "yarn --offline build";
    # TODO why do I have to mkdir $out ?
    installPhase = "mkdir -p $out && cp -r dist $out";
    doDist = false;
  };
in
rustPlatform.buildRustPackage rec {
  pname = "warpgate";
  inherit version;
  inherit src;

  preBuild = ''
    cp -r ${frontend}/dist warpgate-web
  '';
  nativeBuildInputs = [ frontend ];

  RUSTC_BOOTSTRAP = 1;
  RUSTFLAGS = [ "--cfg tokio_unstable" ];
  cargoHash = "sha256-jwCIWmykzRyCYuaWRDm99kGLdk+RSSdsI87/97lpNRI=";

  cargoTestFlags = [ "--workspace" ];

  meta = {
    description = "Smart SSH, HTTPS and MySQL bastion that requires no additional client-side software";
    mainProgram = "warpgate";
    homepage = "https://github.com/warp-tech/warpgate/";
    changelog = "https://github.com/warp-tech/warpgate/releases/tag/v${version}";
    license = lib.licenses.asl20;
    # TODO lib.maintainers.jemand771 after https://github.com/NixOS/nixpkgs/pull/328036
    maintainers = [];
  };
}
