#!/usr/bin/env bash
# install.sh — Install grab-shot to ~/.local/bin and (optionally) create a short-name symlink.
#
# Usage:
#   ./install.sh                   # installs as 'grab-shot' with default dir '.info'
#   ./install.sh gs                # also creates a 'gs' symlink pointing at grab-shot
#   ./install.sh -D notes gs       # bake default dir 'notes' into the installed script
#   ./install.sh -f -D notes gs    # force overwrite (use to upgrade or change baked default)
#
# Flags:
#   -f            force overwrite of existing files / symlinks
#   -D <dir>      bake a different default directory into the installed grab-shot
#                 (overrides the source's '.info' default; per-call -d and $CLAUDE_PASTE_DIR
#                 still take precedence at runtime)
#
# Requires: WSL2 with powershell.exe and wslpath available.

set -e

force=0
default_dir=""
while getopts ":fD:" opt; do
  case $opt in
    f) force=1 ;;
    D) default_dir="$OPTARG" ;;
    *) echo "Usage: $0 [-f] [-D default-dir] [short-name]"; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

short_name="${1:-}"
script_dir="$(cd "$(dirname "$0")" && pwd)"
src="$script_dir/grab-shot"
bin_dir="$HOME/.local/bin"
dest="$bin_dir/grab-shot"

# --- Sanity checks ---------------------------------------------------------
if [ ! -f "$src" ]; then
  echo "ERROR: grab-shot not found next to install.sh (expected: $src)"
  exit 1
fi

if ! command -v powershell.exe >/dev/null 2>&1; then
  echo "ERROR: powershell.exe not found. This script requires WSL2 with Windows interop enabled."
  exit 1
fi

if ! command -v wslpath >/dev/null 2>&1; then
  echo "ERROR: wslpath not found. This script requires WSL."
  exit 1
fi

# --- Install ---------------------------------------------------------------
mkdir -p "$bin_dir"

if [ -e "$dest" ] && [ "$force" -ne 1 ]; then
  echo "NOTE: $dest already exists. Re-run with -f to overwrite."
else
  cp "$src" "$dest"
  chmod +x "$dest"
  echo "Installed: $dest"

  # Bake a custom default directory into the installed copy, if requested.
  # Delegate to 'grab-shot -D' so the self-rewrite logic lives in one place.
  if [ -n "$default_dir" ]; then
    "$dest" -D "$default_dir"
  fi
fi

# --- Short-name symlink ----------------------------------------------------
if [ -n "$short_name" ]; then
  link="$bin_dir/$short_name"
  if [ -e "$link" ] && [ "$force" -ne 1 ]; then
    echo "NOTE: $link already exists. Re-run with -f to overwrite."
  else
    ln -sf "$dest" "$link"
    echo "Symlink created: $link -> $dest"
  fi
fi

# --- Aliases ---------------------------------------------------------------
for alias_name in info-paste paste-info; do
  link="$bin_dir/$alias_name"
  if [ -e "$link" ] && [ "$force" -ne 1 ]; then
    echo "NOTE: $link already exists. Re-run with -f to overwrite."
  else
    ln -sf "$dest" "$link"
    echo "Symlink created: $link -> $dest"
  fi
done

# --- PATH check ------------------------------------------------------------
case ":$PATH:" in
  *":$bin_dir:"*) ;;
  *)
    echo
    echo "WARNING: $bin_dir is not on your PATH."
    echo "Add this to your ~/.bashrc or ~/.zshrc:"
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
    ;;
esac

echo
echo "Done. Capture an image to the Windows clipboard, then run:"
echo "    grab-shot"
[ -n "$short_name" ] && echo "    $short_name"
echo
echo "Inside Claude Code CLI, invoke with '!' — e.g.  ! grab-shot bug-repro"
