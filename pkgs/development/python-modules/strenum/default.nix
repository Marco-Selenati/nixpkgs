{ lib
, buildPythonPackage
, fetchFromGitHub
, pytestCheckHook
, pythonOlder
}:

buildPythonPackage rec {
  pname = "strenum";
  version = "0.4.9";
  format = "setuptools";

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "irgeek";
    repo = "StrEnum";
    rev = "refs/tags/v${version}";
    hash = "sha256-tElXpwyjrgTw9eHqGPgXakY+G9JXkBQYG7jSZSjv6P0=";
  };

  postPatch = ''
    substituteInPlace setup.py \
      --replace '"pytest-runner"' ""
    substituteInPlace pytest.ini \
      --replace " --cov=strenum --cov-report term-missing --black --pylint" ""
  '';

  checkInputs = [
    pytestCheckHook
  ];

  pythonImportsCheck = [
    "strenum"
  ];

  meta = with lib; {
    description = "MOdule for enum that inherits from str";
    homepage = "https://github.com/irgeek/StrEnum";
    changelog = "https://github.com/irgeek/StrEnum/releases/tag/v${version}";
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ fab ];
  };
}
