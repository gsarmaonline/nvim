#!/usr/bin/env bash
# Prints "dark" or "light" for the current system appearance.
# macOS: reads the global AppleInterfaceStyle default.
# Linux: reads the GNOME color-scheme / GTK theme via gsettings. Headless
# machines (no gsettings or no desktop session) fall back to dark.

case "$(uname -s)" in
  Darwin)
    if defaults read -g AppleInterfaceStyle >/dev/null 2>&1; then
      echo dark
    else
      echo light
    fi
    ;;
  *)
    if command -v gsettings >/dev/null 2>&1; then
      scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || true)
      gtk=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || true)
      case "$scheme" in
        *prefer-light*) echo light; exit 0 ;;
        *prefer-dark*)  echo dark;  exit 0 ;;
      esac
      case "$gtk" in
        *-dark*|*-Dark*) echo dark ;;
        "")              echo dark ;;
        *)               echo light ;;
      esac
    else
      echo dark
    fi
    ;;
esac
