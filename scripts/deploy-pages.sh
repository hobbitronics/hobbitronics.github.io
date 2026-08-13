#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASTRO_DIR="$ROOT_DIR/astro"
DIST_DIR="$ASTRO_DIR/dist"

if [[ ! -f "$ASTRO_DIR/package.json" ]]; then
  echo "Error: Astro project not found at $ASTRO_DIR"
  exit 1
fi

echo "Building Astro site..."
npm --prefix "$ASTRO_DIR" run build

if [[ ! -d "$DIST_DIR" ]]; then
  echo "Error: Build output not found at $DIST_DIR"
  exit 1
fi

echo "Copying built files to repository root..."
rsync -a "$DIST_DIR/" "$ROOT_DIR/"

echo "Done. Review with: git status"
