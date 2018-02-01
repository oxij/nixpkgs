{ stdenv, fetchFromGitHub, openssl }:

stdenv.mkDerivation rec {
  pname = "eschalot";
  version = "2018-01-19";
  name = "${pname}-${version}";

  src = fetchFromGitHub {
    owner = "ReclaimYourPrivacy";
    repo = pname;
    rev = "56a967b62631cfd3c7ef68541263dbd54cbbc2c4";
    sha256 = "1iw1jrydasm9dmgpcdimd8dy9n281ys9krvf3fd3dlymkgsj604d";
  };

  buildInputs = [ openssl ];

  installPhase = ''
    install -D -t $out/bin eschalot worgen
  '';

  meta = with stdenv.lib; {
    description = "Tor hidden service name generator";
    license = licenses.isc;
    platforms = platforms.unix;
    maintainers = with maintainers; [ dotlambda ];
  };
}
