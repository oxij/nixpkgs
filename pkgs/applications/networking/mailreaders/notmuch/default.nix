{ fetchurl, stdenv, fixDarwinDylibNames
, pkgconfig, gnupg
, xapian, gmime, talloc, zlib
, doxygen, perl
, pythonPackages
, bash-completion
, emacs
, ruby
, which, dtach, openssl, bash, gdb, man
}:

stdenv.mkDerivation rec {
  version = "0.25";
  name = "notmuch-${version}";

  passthru = {
    pythonSourceRoot = "${name}/bindings/python";
    inherit version;
  };

  src = fetchurl {
    url = "http://notmuchmail.org/releases/${name}.tar.gz";
    sha256 = "02z6d87ip1hkipz8d7w0sfklg8dd5fd5vlgp768640ixg0gqvlk5";
  };

  buildInputs = [
    pkgconfig gnupg # undefined dependencies
    xapian gmime talloc zlib  # dependencies described in INSTALL
    doxygen perl  # (optional) api docs
    pythonPackages.sphinx pythonPackages.python  # (optional) documentation -> doc/INSTALL
    bash-completion  # (optional) dependency to install bash completion
    emacs  # (optional) to byte compile emacs code
    ruby  # (optional) ruby bindings
    which dtach openssl bash  # test dependencies
    ]
    ++ stdenv.lib.optional stdenv.isDarwin fixDarwinDylibNames
    ++ stdenv.lib.optionals (!stdenv.isDarwin) [ gdb man ]; # test

  postPatch = ''
    find test -type f -exec \
      sed -i \
        -e "1s|#!/usr/bin/env bash|#!${bash}/bin/bash|" \
        -e "s|gpg |${gnupg}/bin/gpg |" \
        -e "s| gpg| ${gnupg}/bin/gpg|" \
        -e "s|gpgsm |${gnupg}/bin/gpgsm |" \
        -e "s| gpgsm| ${gnupg}/bin/gpgsm|" \
        -e "s|crypto.gpg_path=gpg|crypto.gpg_path=${gnupg}/bin/gpg|" \
        "{}" ";"

    for src in \
      crypto.c \
      notmuch-config.c \
      emacs/notmuch-crypto.el
    do
      substituteInPlace "$src" \
        --replace \"gpg\" \"${gnupg}/bin/gpg\"
    done
  '';

  makeFlags = "V=1";

  preFixup = stdenv.lib.optionalString stdenv.isDarwin ''
    set -e

    die() {
      >&2 echo "$@"
      exit 1
    }

    prg="$out/bin/notmuch"
    lib="$(find "$out/lib" -name 'libnotmuch.?.dylib')"

    [[ -s "$prg" ]] || die "couldn't find notmuch binary"
    [[ -s "$lib" ]] || die "couldn't find libnotmuch"

    badname="$(otool -L "$prg" | awk '$1 ~ /libtalloc/ { print $1 }')"
    goodname="$(find "${talloc}/lib" -name 'libtalloc.?.?.?.dylib')"

    [[ -n "$badname" ]]  || die "couldn't find libtalloc reference in binary"
    [[ -n "$goodname" ]] || die "couldn't find libtalloc in nix store"

    echo "fixing libtalloc link in $lib"
    install_name_tool -change "$badname" "$goodname" "$lib"

    echo "fixing libtalloc link in $prg"
    install_name_tool -change "$badname" "$goodname" "$prg"
  '';

  doCheck = !stdenv.isDarwin;
  checkTarget = "test V=1";

  postInstall = ''
    make install-man
  '';

  dontGzipMan = true; # already compressed

  meta = with stdenv.lib; {
    description = "Mail indexer";
    homepage    = https://notmuchmail.org/;
    license     = licenses.gpl3;
    maintainers = with maintainers; [ chaoflow garbas ];
    platforms   = platforms.unix;
  };
}
