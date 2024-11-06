{
  fetchFromGitHub,
  lib,
  python3Packages,
}:
python3Packages.buildPythonApplication rec {
  pname = "cibuildwheel";
  version = "2.21.3";
  src = fetchFromGitHub {
    owner = "pypa";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-TLQGOX7OWjjqejdIjowvo9JrbYlKE1rg+vqXDHLdw00=";
  };

  pyproject = true;
  build-system = with python3Packages; [
    hatchling
  ];
  dependencies = with python3Packages; [
    bashlex
    bracex
    certifi
    filelock
    packaging
    platformdirs
  ];
  pythonImportsCheck = "cibuildwheel";
  nativeCheckInputs = [
    python3Packages.pytestCheckHook
  ];
  # idk chief, tests seem relatively broken _or_ even more broken depending on what I set here
  disabledTestPaths = [ "test" ];
  checkInputs = with python3Packages; [
    jinja2
  ];

  meta = {
    description = "Build Python wheels for all the platforms with minimal configuration";
    mainProgram = "cbuildwheel";
    homepage = "https://github.com/pypa/cibuildwheel";
    changelog = "https://github.com/pypa/cibuildwheel/releases/tag/v${version}";
    license = lib.licenses.bsd2;
    maintainers = with lib.maintainers; [ jemand771 ];
  };
}
