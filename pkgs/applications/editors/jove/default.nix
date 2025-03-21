{ lib
, stdenv
, fetchFromGitHub
, groff
, makeWrapper
, ncurses
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "jove";
  version = "4.17.4.7";

  src = fetchFromGitHub {
    owner = "jonmacs";
    repo = "jove";
    rev = finalAttrs.version;
    sha256 = "sha256-a8amp8JAI25XIeL8MzvJEAvv6B0oIaQvUOQlAaS3PeI=";
  };

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [
    groff
    ncurses
  ];

  dontConfigure = true;

  preBuild = ''
    makeFlagsArray+=(SYSDEFS="-DSYSVR4 -D_XOPEN_SOURCE=500" \
      TERMCAPLIB=-lncurses JOVEHOME=${placeholder "out"})
  '';

  postInstall = ''
    wrapProgram $out/bin/teachjove \
      --prefix PATH ":" "$out/bin"
  '';

  meta = with lib; {
    homepage = "https://github.com/jonmacs/jove";
    description = "Jonathan's Own Version of Emacs";
    changelog = "https://github.com/jonmacs/jove/releases/tag/${finalAttrs.version}";
    license = licenses.bsd2;
    maintainers = with maintainers; [ AndersonTorres ];
    platforms = platforms.unix;
    # never built on Hydra: https://hydra.nixos.org/job/nixpkgs/trunk/jove.x86_64-darwin
    broken = stdenv.isDarwin;
  };
})
