#!/usr/bin/env bash
set -euo pipefail
set -x

# CONFIG
BASE_DIR="${GITHUB_WORKSPACE:-/engpro-ai/agent-skills}"
SKILLS_DIR="$BASE_DIR/skills"
PARALLELISM="${PARALLELISM:-4}"

cd "$BASE_DIR"

# INSTALL UV
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"

# CLONE skill-scanner
git clone https://github.com/cisco-ai-defense/skill-scanner

cd skill-scanner

# Setup environment
uv sync --all-extras

SCANNER="$(pwd)/.venv/bin/skill-scanner"

cd "$BASE_DIR"

# LIST ALL COLLECTIONS
COLLECTIONS=$(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d \
  ! -name references \
  ! -name scripts \
  ! -name assets \
  | sort)

echo "Collections to scan:"
echo "$COLLECTIONS"

# RUN SCAN (PARALLEL)
echo "$COLLECTIONS" | xargs -I{} -P "$PARALLELISM" bash -c '
  COLLECTION_PATH="{}"

  if [ -d "$COLLECTION_PATH" ]; then
    echo "Scanning collection: $COLLECTION_PATH"
    "'"$SCANNER"'" scan-all "$COLLECTION_PATH"
  else
    echo "Skipping (not found): $COLLECTION_PATH"
  fi
'

echo "✅ Scan finished successfully!"
