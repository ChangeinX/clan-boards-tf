#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <distribution_id>" >&2
  exit 1
fi

aws cloudfront create-invalidation \
  --distribution-id "$1" \
  --paths "/*"
