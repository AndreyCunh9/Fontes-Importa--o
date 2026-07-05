#!/usr/bin/env bash
set -euo pipefail
set -x

# Config
BASE_DIR="/engpro-ai/agent-skills"
SKILLS_DIR="$BASE_DIR/skills"
RELEASE_DIR="$BASE_DIR/release"
AGENTS_DIR="$BASE_DIR/agents"

mkdir -p "$RELEASE_DIR"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Zip the entire skills folder
if [ -d "$SKILLS_DIR" ]; then
	echo "Packaging skills"
	(cd "$BASE_DIR" && zip -r "$TMP_DIR/skills.zip" "skills")
fi

# Zip agents directory
if [ -d "$AGENTS_DIR" ]; then
	echo "Packaging agents"
	(cd "$BASE_DIR" && zip -r "$TMP_DIR/agents.zip" "agents")
fi

# Move zips to release
if compgen -G "$TMP_DIR/*.zip" > /dev/null; then
	mv "$TMP_DIR"/*.zip "$RELEASE_DIR"/
fi

# Copy all agent files to release
if [ -d "$BASE_DIR/instructions" ]; then
	echo "Copying agent files to release"
	cp -r "$BASE_DIR/instructions/"* "$RELEASE_DIR"/
fi

# List generated zips
if compgen -G "$RELEASE_DIR/*.zip" > /dev/null; then
	ls -1 "$RELEASE_DIR"/*.zip
else
	echo "No zip files generated."
fi
