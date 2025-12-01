#!/bin/bash
# Temporarily move .zshenv out of the way so template can capture clean PATH
if [ -f "$HOME/.zshenv" ]; then
    mv "$HOME/.zshenv" "$HOME/.zshenv.backup"
fi
