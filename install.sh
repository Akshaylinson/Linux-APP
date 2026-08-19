#!/usr/bin/env bash
set -e

BUNDLE_DIR="$(cd "$(dirname "$0")" && pwd)/build/linux/x64/release/bundle"
INSTALL_DIR="$HOME/.local/share/systemlens"
DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"

echo "Installing SystemLens..."

# 1. Copy the bundle
mkdir -p "$INSTALL_DIR"
cp -r "$BUNDLE_DIR"/. "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/systemlens"

# 2. Install the SVG icon
mkdir -p "$ICON_DIR"
cp assets/systemlens_icon.svg "$ICON_DIR/systemlens.svg"

# 3. Write the .desktop file with absolute paths
mkdir -p "$DESKTOP_DIR"
cat > "$DESKTOP_DIR/systemlens.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=SystemLens
Comment=Linux system monitoring dashboard
Exec=$INSTALL_DIR/systemlens
Icon=$ICON_DIR/systemlens.svg
Terminal=false
Categories=System;Utility;Monitor;
StartupWMClass=systemlens
EOF

# 4. Refresh the desktop database
update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true

echo ""
echo "Done! SystemLens installed to $INSTALL_DIR"
echo "It should now appear in your application launcher."
echo ""
echo "To run it directly:"
echo "  $INSTALL_DIR/systemlens"
