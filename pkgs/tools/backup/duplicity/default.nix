{ lib
, stdenv
, fetchFromGitLab
, python3
, librsync
, ncftp
, gnupg
, gnutar
, par2cmdline
, util-linux
, rsync
, makeWrapper
, gettext
, getconf
, testers
}:

let self = python3.pkgs.buildPythonApplication rec {
  pname = "duplicity";
  version = "2.2.3";

  src = fetchFromGitLab {
    owner = "duplicity";
    repo = "duplicity";
    rev = "rel.${version}";
    hash = "sha256-4IwKqXlG7jh1siuPT5pVgiYB+KlmCzF6+OMPT3I3yTQ=";
  };

  patches = [
    ./keep-pythonpath-in-testing.patch
  ];

  postPatch = ''
    patchShebangs duplicity/__main__.py

    # don't try to use gtar on darwin/bsd
    substituteInPlace testing/functional/test_restart.py \
      --replace-fail 'tarcmd = "gtar"' 'tarcmd = "tar"'
  '' + lib.optionalString stdenv.isDarwin ''
    # tests try to access these files in the sandbox, but can't deal with EPERM
    substituteInPlace testing/unit/test_globmatch.py \
      --replace-fail /var/log /test/log
    substituteInPlace testing/unit/test_selection.py \
      --replace-fail /usr/bin /dev
    # don't use /tmp/ in tests
    substituteInPlace duplicity/backends/_testbackend.py \
      --replace-fail '"/tmp/' 'os.environ.get("TMPDIR")+"/'
  '';

  disabledTests = lib.optionals stdenv.isDarwin [
    # uses /tmp/
    "testing/unit/test_cli_main.py::CommandlineTest::test_intermixed_args"
  ];

  nativeBuildInputs = [
    makeWrapper
    gettext
    python3.pkgs.wrapPython
    python3.pkgs.setuptools-scm
  ];

  buildInputs = [
    librsync
  ];

  pythonPath = with python3.pkgs; [
    b2sdk
    boto3
    cffi
    cryptography
    ecdsa
    idna
    pygobject3
    fasteners
    lockfile
    paramiko
    pyasn1
    pycrypto
    pydrive2
    future
  ];

  nativeCheckInputs = [
    gnupg # Add 'gpg' to PATH.
    gnutar # Add 'tar' to PATH.
    librsync # Add 'rdiff' to PATH.
    par2cmdline # Add 'par2' to PATH.
  ] ++ lib.optionals stdenv.isLinux [
    util-linux # Add 'setsid' to PATH.
  ] ++ lib.optionals stdenv.isDarwin [
    getconf
  ] ++ (with python3.pkgs; [
    lockfile
    mock
    pexpect
    pytest
    pytest-runner
    fasteners
  ]);

  postInstall = let
    binPath = lib.makeBinPath ([
      gnupg
      ncftp
      rsync
    ] ++ lib.optionals stdenv.isDarwin [
      getconf
    ]); in ''
    wrapProgram $out/bin/duplicity \
      --prefix PATH : "${binPath}"
  '';

  preCheck = ''
    # tests need writable $HOME
    HOME=$PWD/.home

    wrapPythonProgramsIn "$PWD/testing/overrides/bin" "$pythonPath"
  '';

  doCheck = true;

  passthru = {
    tests.version = testers.testVersion {
      package = self;
    };
  };

  meta = with lib; {
    description = "Encrypted bandwidth-efficient backup using the rsync algorithm";
    homepage = "https://duplicity.gitlab.io/duplicity-web/";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ corngood ];
  };
};

in self
