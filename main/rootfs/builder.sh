#!/usr/bin/env bash

# Copyright 2015 The Prometheus Authors
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

# This is a Makefile based building processus
[ ! -e "./Makefile" ] && echo "Error: A Makefile with a 'build' target must be present into the root of your source files" && exit 1

usage() {
  base="$(basename "$0")"
  cat <<EOUSAGE
Usage: $base [args]
  -d,--docker           : Build the final image
  -i,--import-path arg  : Go import path of the project
  -l,--latest           : Tag the final image as latest
  -p,--platforms arg    : List of platforms (GOOS/GOARCH) to build separated by a space
  -t,--tag arg          : Docker tag for the final image
  -T,--tests            : Go run tests
EOUSAGE
}

if [ $# -eq 0 ]; then
  usage
fi

# Flag parsing
while [[ $# -gt 0 ]]; do
  opt="$1"
  case "${opt}" in
    -d|--docker)
      docker=1
      shift
      ;;
    -i|--import-path)
      repoName="$2"
      shift 2
      ;;
    -l|--latest)
      latest=1
      shift
      ;;
    -p|--plateforms)
      IFS=' ' read -r -a goarchs <<< "$2"
      shift 2
      ;;
    -t|--tag)
      tagName="$2"
      shift 2
      ;;
    -T|--tests)
      tests=1
      shift
      ;;
    *)
      echo "Error: Unkown option: ${opt}"
      usage
      exit 1
      ;;
  esac
done

[ -z "${repoName}" ] && echo "Error: {-i,--import-path} option is mandatory" && exit 1

# Get first path listed in GOPATH
goPath="${GOPATH%%:*}"
repoPath="${goPath}/src/${repoName}"

# Simulate the go src path with a symlink
mkdir -p "$(dirname "${repoPath}")"
ln -sf /app "${repoPath}"

# Running tests
# The `test` Makefile target is required
tests=${tests:-0}
if [ ${tests} -eq 1 ]; then
  # Need to be in the proper GOPATH to run tests
  cd "${repoPath}" ; make test
  exit 0
fi


# Building binaries for the specified platforms
# The `build` Makefile target is required
goarchs=(${goarchs[@]:-linux\/amd64})
for goarch in "${goarchs[@]}"
do
  goos=${goarch%%/*}
  arch=${goarch##*/}

  if [ "${goos}" = "windows" ]; then
    if [ "${arch}" = "386" ]; then
      CC="i686-w64-mingw32-gcc" CXX="i686-w64-mingw32-g++" CGO_ENABLED=1 GOOS=${goos} GOARCH=${arch} make build
    else
      CC="x86_64-w64-mingw32-gcc" CXX="x86_64-w64-mingw32-g++" CGO_ENABLED=1 GOOS=${goos} GOARCH=${arch} make build
    fi
  elif [ "${goos}" = "darwin" ]; then
    if [ "${arch}" = "386" ]; then
      CC="o32-clang" CXX="o32-clang++" CGO_ENABLED=1 GOOS=${goos} GOARCH=${arch} make build
    else
      CC="o64-clang" CXX="o64-clang++" CGO_ENABLED=1 GOOS=${goos} GOARCH=${arch} make build
    fi
  else
    CGO_ENABLED=1 GOOS=${goos} GOARCH=${arch} make build
  fi
done

# Building the final docker image
docker=${docker:-0}
if [ ${docker} -eq 1 ]; then
  [ ! -e "/run/docker.sock" ] && echo "Error: Docker socket must be mount into /run/docker.sock" && exit 1
  [ ! -e "./Dockerfile" ] && echo "Error: A Dockerfile must be present into the root of your source files" && exit 1

  # Get the last part of the repository name
  defaultName=${repoName##*/}
  # Branch name as default tag
  defaultTag=$( git rev-parse --abbrev-ref HEAD 2> /dev/null || echo 'unknown' )
  tagName=${tagName:-${defaultName}:${defaultTag}}
  latest=${latest:-0}

  # Some additionnal files necessary to fix `From scratch` issues
  cp -a /etc/ssl/certs/ca-certificates.crt ./
  tar cfz zoneinfo.tar.gz -C / usr/share/zoneinfo
  mkdir ./emptydir

  echo ">> building final docker image"
  echo " >   ${tagName}"
  docker build -t "${tagName}" .

  if [ ${latest} -eq 1 ]; then
    echo ">> tagging final docker image as latest"
    docker tag -f "${tagName}" "${tagName%%:*}:latest"
  fi

  # Cleaning fixing files
  rm -rf ./ca-certificates.crt zoneinfo.tar.gz emptydir/
fi

exit 0
