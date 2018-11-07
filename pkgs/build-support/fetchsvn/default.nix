{ lib, stdenvNoCC, subversion, glibcLocales, sshSupport ? false, openssh ? null }:
{ url, rev ? "HEAD", md5 ? null, sha256 ? null
, ignoreExternals ? false, ignoreKeywords ? false
, name ? lib.repoToName "svn" url rev }:

if md5 != null then
  throw "fetchsvn does not support md5 anymore, please use sha256"
else
stdenvNoCC.mkDerivation {
  inherit name;

  builder = ./builder.sh;
  nativeBuildInputs = [ subversion glibcLocales ];

  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  outputHash = sha256;

  inherit url rev sshSupport openssh ignoreExternals ignoreKeywords;

  impureEnvVars = lib.fetchers.proxyImpureEnvVars;
  preferLocalBuild = true;
}
