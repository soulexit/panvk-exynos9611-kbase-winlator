#!/bin/sh
# Shared helpers. Source this file, do not execute it.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
VERSION=$(cat "$ROOT/VERSION")
DIST_DIR=${DIST_DIR:-$ROOT/dist}
BUILD_ROOT=${BUILD_ROOT:-$ROOT/build}
SOURCE_REPO=${SOURCE_REPO:-https://github.com/soulexit/panvk-exynos9611-kbase-termux.git}
SOURCE_TAG=${SOURCE_TAG:-v$VERSION}
RELEASE_URL=${RELEASE_URL:-https://github.com/soulexit/panvk-exynos9611-kbase-termux/releases/download/$SOURCE_TAG}
PACKAGE_NAME=panvk-exynos9611-winlator-v$VERSION
WINLATOR_PACKAGE=${WINLATOR_PACKAGE:-com.winlator.cmod}

log() { printf '==> %s\n' "$*" >&2; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "$1 not found in PATH"; }
