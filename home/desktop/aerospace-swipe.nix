# aerospace-swipe — trackpad gesture support for AeroSpace
# https://github.com/acsandmann/aerospace-swipe
#
# Built from source: upstream deleted their GitHub release assets, so the
# homebrew cask (acsandmann/tap) 404s. The build is five clang files linking
# the private MultitouchSupport framework — trivial to build ourselves and
# fully pinned. Consumed by modules/desktop/aerospace.nix via callPackage.
{ stdenv, fetchFromGitHub, lld }:

stdenv.mkDerivation {
  pname = "aerospace-swipe";
  # Pinned to PR #27 (KorigamiK fork): upstream master (fc3db875) speaks the
  # pre-v0.21 AeroSpace socket protocol and fails with "Broken pipe / Unable
  # to retrieve workspace list" against AeroSpace 0.21+, which switched to
  # length-prefixed JSON frames. Re-point at upstream once #27 merges.
  version = "unstable-2026-07-12-pr27";

  src = fetchFromGitHub {
    owner = "KorigamiK";
    repo = "aerospace-swipe";
    rev = "2149abf8af1b8268c3444786d4d78bb96a319cb2";
    hash = "sha256-VsqhN5hUZk3ehVwShvL+4WClvLU+CJGGAnHyJKAwteo=";
  };

  # Upstream makefile uses -march=native (impure) and builds an app bundle +
  # launch agent we don't want — the launchd agent is managed declaratively in
  # aerospace.nix, so compile just the binary.
  # --ld-path: nixpkgs' cctools ld (1010.6) crashes (SIGTRAP) linking these
  # ObjC objects against the private MultitouchSupport framework; lld links
  # them fine.
  buildPhase = ''
    runHook preBuild
    clang -std=c99 -O2 -fobjc-arc \
      --ld-path=${lld}/bin/ld64.lld \
      src/aerospace.c src/yyjson.c src/haptic.c src/event_tap.m src/main.m \
      -framework CoreFoundation -framework IOKit \
      -F/System/Library/PrivateFrameworks -framework MultitouchSupport \
      -framework ApplicationServices -framework Cocoa \
      -o swipe
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 swipe $out/bin/aerospace-swipe
    runHook postInstall
  '';

  meta = {
    description = "Switch AeroSpace workspaces with trackpad swipes";
    homepage = "https://github.com/acsandmann/aerospace-swipe";
    platforms = [ "aarch64-darwin" "x86_64-darwin" ];
  };
}
