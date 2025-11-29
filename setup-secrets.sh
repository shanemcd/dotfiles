#!/bin/bash
# Helper script to decrypt secrets on a new machine
# Run this once after: chezmoi init git@github.com:shanemcd/dotfiles.git

set -e

ENCRYPTED_SECRETS="$HOME/.config/chezmoi/chezmoi-secrets.toml.age"
LOCAL_CONFIG="$HOME/.config/chezmoi/chezmoi.toml"
AGE_KEY="$HOME/.config/chezmoi/key.txt"

echo "🔐 Chezmoi Secrets Setup"
echo

# Check if age key exists
if [ ! -f "$AGE_KEY" ]; then
    echo "❌ Age key not found at $AGE_KEY"
    echo
    echo "Please restore your age key from backup:"
    echo "  1. Copy key.txt from 1Password/USB/backup"
    echo "  2. Save it to $AGE_KEY"
    echo "  3. Run: chmod 600 $AGE_KEY"
    echo "  4. Run this script again"
    exit 1
fi

# Check if encrypted secrets exist
if [ ! -f "$ENCRYPTED_SECRETS" ]; then
    echo "❌ Encrypted secrets not found at $ENCRYPTED_SECRETS"
    echo
    echo "Run 'chezmoi apply' first to fetch the encrypted secrets file"
    exit 1
fi

# Decrypt
echo "Decrypting secrets..."
if age -d -i "$AGE_KEY" -o "$LOCAL_CONFIG" "$ENCRYPTED_SECRETS"; then
    echo "✅ Successfully decrypted secrets to $LOCAL_CONFIG"
    echo
    echo "Next steps:"
    echo "  1. Run: chezmoi apply -v"
    echo "  2. Restart your shell or run: source ~/.zshrc"
else
    echo "❌ Failed to decrypt secrets"
    exit 1
fi
