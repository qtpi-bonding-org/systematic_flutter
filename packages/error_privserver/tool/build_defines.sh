#!/bin/sh
set -eu
version=$(awk '/^version:/{print $2; exit}' pubspec.yaml)
commit=$(git rev-parse --short HEAD)
printf '%s\n' "--dart-define=APP_VERSION=$version --dart-define=GIT_COMMIT=$commit"
