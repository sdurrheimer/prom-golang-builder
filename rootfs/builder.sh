#!/usr/bin/env bash

set -e

[ ! -e "/run/docker.sock" ] && echo "Error: Docker socket must be mount into /run/docker.sock" && exit 1
[ ! -e "./Dockerfile" ] && echo "Error: A Dockerfile must be present into the root of your source files" && exit 1

usage() {
  base="$(basename "$0")"
  cat <<EOUSAGE
Usage: $base [args]
  -p,--path arg : import path
  -t,--tag arg  : docker tag for the final image
  -l,--latest   : tag final image as latest 
EOUSAGE
}

if [ $# -eq 0 ]; then
  usage
fi

while [[ $# > 0 ]]; do
  opt="$1"
  case $opt in
    -p|--path)
      repoName="$2"
      shift 2
    ;;
    -t|--tag)
      tagName="$2"
      shift 2
    ;;
    -l|--latest)
      latest=1
      shift
    ;;
    *)
      echo "Error: Unkown option: ${opt}"
      usage
      exit 1
    ;;
  esac
done

[ -z "${repoName}" ] && echo "Error: {-p,--path} option is mandatory" && exit 1

goPath="${GOPATH%%:*}"
repoPath="$goPath/src/$repoName"

mkdir -p "$(dirname "$repoPath")"
ln -sf /app "$repoPath"

make build

defaultName=${repoName##*/}
defaultTag=$( git rev-parse --abbrev-ref HEAD 2> /dev/null || echo 'unknown' )
tagName=${tagName:-${defaultName}:${defaultTag}}
latest=${latest:-0}

cp -a /etc/ssl/certs/ca-certificates.crt ./
tar cfz zoneinfo.tar.gz -C / usr/share/zoneinfo
mkdir ./emptydir

echo ">> building final docker image"
echo " >   ${tagName}"
docker build -t "${tagName}" .

if [ $latest -eq 1 ]; then
  echo ">> tagging final docker image as latest"
  docker tag -f "${tagName}" "${tagName%%:*}:latest"
fi

rm -rf ./ca-certificates.crt zoneinfo.tar.gz emptydir/

exit 0
