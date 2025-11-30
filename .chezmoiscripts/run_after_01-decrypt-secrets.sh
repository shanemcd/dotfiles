#!/bin/bash
# Automatically decrypt secrets on every chezmoi apply
# Exits early if secrets are already up-to-date

set -e

ENCRYPTED_SECRETS="$HOME/.config/chezmoi/chezmoi-secrets.toml.age"
LOCAL_CONFIG="$HOME/.config/chezmoi/chezmoi.toml"
AGE_KEY="$HOME/.config/chezmoi/key.txt"

echo "🔐 Auto-decrypting chezmoi secrets..."
echo

# Check if secrets need to be re-decrypted (encrypted file is newer)
if [ -f "$LOCAL_CONFIG" ] && [ -f "$ENCRYPTED_SECRETS" ]; then
    if [ "$LOCAL_CONFIG" -nt "$ENCRYPTED_SECRETS" ]; then
        # Decrypted file is newer, no need to re-decrypt
        exit 0
    fi
fi

# Check if age key exists
if [ ! -f "$AGE_KEY" ]; then
    echo "⚠️  Age key not found at $AGE_KEY"
    echo
    echo "To complete setup:"
    echo "  1. Restore your age key from backup (1Password, USB, etc.)"
    echo "  2. Save it to $AGE_KEY"
    echo "  3. Run: chmod 600 $AGE_KEY"
    echo "  4. Run: chezmoi apply -v"
    echo
    echo "Skipping secret decryption for now..."
    exit 0
fi

# Check if encrypted secrets exist
if [ ! -f "$ENCRYPTED_SECRETS" ]; then
    echo "⚠️  Encrypted secrets not found at $ENCRYPTED_SECRETS"
    echo
    echo "This might be your first run. The secrets file will be fetched on the next 'chezmoi apply'"
    exit 0
fi

# Decrypt
echo "Decrypting secrets..."
if age -d -i "$AGE_KEY" -o "$LOCAL_CONFIG" "$ENCRYPTED_SECRETS" 2>/dev/null; then
    echo "✅ Successfully decrypted secrets to $LOCAL_CONFIG"
    echo
    echo "🎉 Bootstrap complete! Your dotfiles are ready."
    echo "   Restart your shell or run: source ~/.zshrc"
else
    echo "❌ Failed to decrypt secrets"
    echo
    echo "This might mean:"
    echo "  - Wrong age key"
    echo "  - Corrupted encrypted file"
    echo
    echo "Run this manually to see the error: ~/.local/share/chezmoi/setup-secrets.sh"
    exit 1
fi
