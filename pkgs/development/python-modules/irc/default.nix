{
  lib,
  buildPythonPackage,
  fetchPypi,
  jaraco-collections,
  jaraco-itertools,
  jaraco-logging,
  jaraco-stream,
  jaraco-text,
  pytestCheckHook,
  pythonOlder,
  pytz,
  setuptools-scm,
  importlib-resources,
}:

buildPythonPackage (finalAttrs: {
  pname = "irc";
  version = "20.5.0";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-jdv9GfcSBM7Ount8cnJLFbP6h7q16B5Fp1vvc2oaPHY=";
  };

  nativeBuildInputs = [ setuptools-scm ];

  propagatedBuildInputs = [
    jaraco-collections
    jaraco-itertools
    jaraco-logging
    jaraco-stream
    jaraco-text
    pytz
  ]
  ++ lib.optionals (pythonOlder "3.12") [ importlib-resources ];

  nativeCheckInputs = [ pytestCheckHook ];

  disabledTests = [
    # RuntimeError: There is no current event loop in thread 'MainThread' (Python 3.10+)
    "test_privmsg_sends_msg"
  ];

  __darwinAllowLocalNetworking = true;

  pythonImportsCheck = [ "irc" ];

  meta = {
    description = "IRC (Internet Relay Chat) protocol library for Python";
    homepage = "https://github.com/jaraco/irc";
    changelog = "https://github.com/jaraco/irc/blob/v${finalAttrs.version}/NEWS.rst";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
})
