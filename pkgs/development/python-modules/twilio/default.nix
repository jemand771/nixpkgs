{
  lib,
  aiohttp,
  aiohttp-retry,
  aiounittest,
  buildPythonPackage,
  cryptography,
  django,
  fetchFromGitHub,
  mock,
  multidict,
  pyngrok,
  pyjwt,
  pytestCheckHook,
  pythonOlder,
  pytz,
  requests,
  setuptools,
}:

buildPythonPackage rec {
  pname = "twilio";
  version = "9.3.4";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "twilio";
    repo = "twilio-python";
    rev = "refs/tags/${version}";
    hash = "sha256-74tJt3BfSKfsl0A1gz7XVzlvumQ8H++Nfp+SEknMYcY=";
  };

  build-system = [ setuptools ];

  dependencies = [
    aiohttp
    aiohttp-retry
    pyjwt
    pyngrok
    pytz
    requests
  ];

  # aiounittest is not supported on 3.12
  doCheck = pythonOlder "3.12";

  nativeCheckInputs = [
    aiounittest
    cryptography
    django
    mock
    multidict
    pytestCheckHook
  ];

  disabledTests = [
    # Tests require network access
    "test_set_default_user_agent"
    "test_set_user_agent_extensions"
  ];

  disabledTestPaths = [
    # Tests require API token
    "tests/cluster/test_webhook.py"
    "tests/cluster/test_cluster.py"
  ];

  pythonImportsCheck = [ "twilio" ];

  meta = with lib; {
    description = "Twilio API client and TwiML generator";
    homepage = "https://github.com/twilio/twilio-python/";
    changelog = "https://github.com/twilio/twilio-python/blob/${version}/CHANGES.md";
    license = licenses.mit;
    maintainers = with maintainers; [ fab ];
  };
}
