#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${HIVE_HOME:-}" ]]; then
  echo "Source scripts/project_env.sh first." >&2
  exit 1
fi
BEELINE_URL=${BEELINE_URL:-jdbc:hive2://127.0.0.1:10000/default}
exec "$HIVE_HOME/bin/beeline" -u "$BEELINE_URL" -n "$(id -un)" "$@"
