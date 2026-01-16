#!/bin/bash
# Update submodule to latest remote (runs on every chezmoi command)
# Fast no-op if already up to date
git -C "${CHEZMOI_SOURCE_DIR:-$HOME/.local/share/chezmoi}" submodule update --remote external_secrets 2>/dev/null || true
