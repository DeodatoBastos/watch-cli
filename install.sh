#!/usr/bin/env bash
set -e

echo "======================================"
echo "    Installing watch-cli              "
echo "======================================"

# Check for required commands
for req in git make bash fzf python3 ffprobe; do
    if ! command -v "$req" >/dev/null 2>&1; then
        echo "Error: Required dependency '$req' is not installed."
        echo "Please install it and try again."
        exit 1
    fi
done

if ! command -v mpv >/dev/null 2>&1; then
    echo "Warning: 'mpv' is not installed. Playback and auto-tracking require it."
fi

TMP_DIR=$(mktemp -d -t watch-cli-install-XXXXXX)

echo "-> Cloning repository..."
git clone --depth 1 https://github.com/DeodatoBastos/watch-cli.git "$TMP_DIR" >/dev/null 2>&1

echo "-> Installing..."
cd "$TMP_DIR"
make install

echo "-> Cleaning up..."
cd - >/dev/null
rm -rf "$TMP_DIR"

echo "======================================"
echo "Installation Complete!"
echo "Run 'watch-cli' to get started."
echo "Note: Make sure ~/.local/bin is in your PATH."
echo "======================================"
