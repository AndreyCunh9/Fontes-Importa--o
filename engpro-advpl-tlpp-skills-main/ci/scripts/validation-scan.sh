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

# CLONE agentskills
git clone --depth 1 https://github.com/agentskills/agentskills

cd agentskills/skills-ref

# Setup environment
uv venv
uv pip install -e .

SCANNER="$(pwd)/.venv/bin/skills-ref"

# BACK TO REPO
cd "$BASE_DIR"

# LIST ALL SKILLS (IGNORING UNWANTED FOLDERS)
ALL_SKILLS=$(find "$SKILLS_DIR" -mindepth 2 -maxdepth 2 -type d \
  ! -name references \
  ! -name scripts \
  ! -name assets \
  | sed "s|^$BASE_DIR/||" \
  | grep -E "^skills/[^/]+/[^/]+$" \
  | sort)

echo "All skills to validate:"
echo "$ALL_SKILLS"

# VALIDATION (PARALLEL)
echo "$ALL_SKILLS" | xargs -I{} -P "$PARALLELISM" bash -c '
  SKILL_DIR="{}"
  FULL_PATH="'"$BASE_DIR"'/$SKILL_DIR"

  if [[ "$SKILL_DIR" =~ ^skills/[^/]+/[^/]+$ ]]; then
    if [ -d "$FULL_PATH" ]; then
      echo "Validating $SKILL_DIR"
      "'"$SCANNER"'" validate "$FULL_PATH"
    else
      echo "Skipping (not found): $SKILL_DIR"
    fi
  else
    echo "Skipping invalid path: $SKILL_DIR"
  fi
'

echo "✅ Full validation finished successfully!"
