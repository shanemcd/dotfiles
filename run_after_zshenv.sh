#!/bin/bash
# Clean up backup file after .zshenv has been templated
if [ -f "$HOME/.zshenv.backup" ]; then
    rm "$HOME/.zshenv.backup"
fi
