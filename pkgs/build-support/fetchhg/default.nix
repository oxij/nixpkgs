{ lib, stdenvNoCC, mercurial }:
{ url, rev ? "tip", md5 ? null, sha256 ? null
, fetchSubrepos ? false
, name ? lib.repoToName "hg" url rev
}:

if md5 != null then
  throw "fetchhg does not support md5 anymore, please use sha256"
else
# TODO: statically check if mercurial as the https support if the url starts woth https.
stdenvNoCC.mkDerivation {
  inherit name;

  builder = ./builder.sh;
  nativeBuildInputs = [mercurial];

  impureEnvVars = lib.fetchers.proxyImpureEnvVars;

  subrepoClause = if fetchSubrepos then "S" else "";

  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  outputHash = sha256;

  inherit url rev;
  preferLocalBuild = true;
}
