{
  lib,
  buildPythonPackage,
  debian-inspector,
  docker,
  dockerfile-parse,
  fetchPypi,
  gitpython,
  idna,
  license-expression,
  packageurl-python,
  pbr,
  prettytable,
  pyyaml,
  regex,
  requests,
  stevedore,
  versionCheckHook,
}:

buildPythonPackage rec {
  pname = "tern";
  version = "2.12.1";
  format = "setuptools";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-yMIvFiliEHrbZMqvX3ZAROWcqii5VmB54QEYHGRJocA=";
  };

  preBuild = ''
    cp requirements.{in,txt}
  '';

  nativeBuildInputs = [
    pbr
    versionCheckHook
  ];

  propagatedBuildInputs = [
    pyyaml
    docker
    dockerfile-parse
    license-expression
    requests
    stevedore
    debian-inspector
    regex
    gitpython
    prettytable
    idna
    packageurl-python
  ];

  pythonImportsCheck = [ "tern" ];

  meta = {
    description = "Software composition analysis tool and Python library that generates a Software Bill of Materials for container images and Dockerfiles";
    mainProgram = "tern";
    homepage = "https://github.com/tern-tools/tern";
    changelog = "https://github.com/tern-tools/tern/releases/tag/v${version}";
    license = lib.licenses.bsd2;
    maintainers = [ ];
  };
}
