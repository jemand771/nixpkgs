{
  lib,
  buildPythonPackage,
  fetchPypi,
  cython,
  isPyPy,
  ipython,
  scikit-build,
  cmake,
  pytestCheckHook,
  ubelt,
}:

buildPythonPackage rec {
  pname = "line-profiler";
  version = "5.0.0";
  format = "setuptools";

  disabled = isPyPy;

  src = fetchPypi {
    pname = "line_profiler";
    inherit version;
    hash = "sha256-qA8K+wW6DSddnd3F/5fqtjdHEWf/Pmbcx9E1dVBZOYw=";
  };

  nativeBuildInputs = [
    cython
    cmake
    scikit-build
  ];

  optional-dependencies = {
    ipython = [ ipython ];
  };

  nativeCheckInputs = [
    pytestCheckHook
    ubelt
  ]
  ++ optional-dependencies.ipython;

  dontUseCmakeConfigure = true;

  preBuild = ''
    rm -f _line_profiler.c
  '';

  preCheck = ''
    rm -r line_profiler
    export PATH=$out/bin:$PATH
  '';

  disabledTests = [
    # assert 21 > 100, profiling count differs in Python 3.14
    "test_varied_complex_invocations"
  ];

  disabledTestPaths = [
    # sys.monitoring API changes in Python 3.14
    "tests/test_sys_monitoring.py"
    # Cython source recovery fails
    "tests/test_cython.py"
  ];

  pythonImportsCheck = [ "line_profiler" ];

  meta = {
    description = "Line-by-line profiler";
    mainProgram = "kernprof";
    homepage = "https://github.com/pyutils/line_profiler";
    changelog = "https://github.com/pyutils/line_profiler/blob/v${version}/CHANGELOG.rst";
    license = lib.licenses.bsd3;
  };
}
