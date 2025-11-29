#!/bin/bash
# Clone the private secrets repository if it doesn't exist
# This runs once before other scripts, ensuring secrets are available

SECRETS_REPO="$HOME/.local/share/dotfiles-secrets"

if [ ! -d "$SECRETS_REPO" ]; then
    echo "Cloning dotfiles-secrets repository..."
    git clone git@github.com:shanemcd/dotfiles-secrets.git "$SECRETS_REPO"
    echo "✓ Secrets repository cloned"
else
    echo "Secrets repository already exists"
fi
