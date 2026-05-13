#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$ROOT_DIR/dist/package"
ZIP_PATH="$ROOT_DIR/dist/lambda.zip"

echo ">>> Building Lambda deployment package..."
rm -rf "$BUILD_DIR" "$ZIP_PATH"
mkdir -p "$BUILD_DIR"

echo ">>> Installing Python dependencies..."
pip install -r "$ROOT_DIR/src/requirements.txt" -t "$BUILD_DIR" --quiet

echo ">>> Copying Lambda handler..."
cp "$ROOT_DIR/src/lambda_function.py" "$BUILD_DIR/"

echo ">>> Creating zip archive..."
cd "$BUILD_DIR"
zip -r "$ZIP_PATH" . -x "*.pyc" -x "*/__pycache__/*" -x "*.dist-info/*" > /dev/null
cd - > /dev/null

echo ">>> Done: $ZIP_PATH ($(du -sh "$ZIP_PATH" | cut -f1))"
