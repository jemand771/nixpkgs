{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  six,
  pytestCheckHook,
  pyopenssl,
  pyspnego,
  namedlist,
  pydes,
  cryptography,
}:

buildPythonPackage rec {
  pname = "python-tds";
  version = "1.17.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "denisenkom";
    repo = "pytds";
    tag = version;
    hash = "sha256-W9Sk2X2bSMjtRu1XPnjWXOLjVVa+MYC7+ttrZc48c4I=";
  };

  postPatch = ''
    substituteInPlace setup.py \
      --replace-fail "version.get_git_version()" '"${version}"'
    # conftest.py uses a deprecated pytest-mypy API that no longer works
    echo "" > conftest.py
  '';

  build-system = [ setuptools ];

  dependencies = [ six ];

  nativeCheckInputs = [
    pytestCheckHook
    pyopenssl
    pyspnego
    namedlist
    pydes
    cryptography
  ];

  disabledTestPaths = [
    # All connected tests require a live MSSQL database
    "tests/connected_test.py"
    "tests/fedauth_test.py"
    "tests/sqlalchemy_test.py"
    "tests/transaction_test.py"
    "tests/types_test.py"
  ];

  disabledTests = [
    # ImportError: ntlm-auth has been removed from nixpkgs
    "test_ntlm"
  ];

  pythonImportsCheck = [ "pytds" ];

  meta = {
    description = "Python DBAPI driver for MSSQL using pure Python TDS (Tabular Data Stream) protocol implementation";
    homepage = "https://python-tds.readthedocs.io/";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
}
