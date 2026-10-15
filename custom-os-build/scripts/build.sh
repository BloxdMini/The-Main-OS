#!/usr/bin/env bash
set -Eeuo pipefail

exec "$(dirname "$0")/build-live-iso.sh" "$@"