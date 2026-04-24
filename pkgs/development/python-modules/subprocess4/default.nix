{
  lib,
  buildPythonPackage,
  fetchPypi,
  hatchling,
  pytestCheckHook,
}:

buildPythonPackage rec {
  pname = "subprocess4";
  version = "0.1.1";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-1Hc2L+mCSWqT48BGGzMAuOt1110vORcOIvGDCcsCyiY=";
  };

  build-system = [ hatchling ];

  nativeCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "subprocess4" ];

  meta = {
    description = "Python subprocess wrapper using os.wait4 to get resource usage";
    homepage = "https://github.com/JasonGross/subprocess4";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
}
