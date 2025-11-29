# Dotfiles managed with chezmoi

## Quick Start

### On this machine
```bash
# Add a file to chezmoi
chezmoi add ~/.zshrc

# Edit a managed file
chezmoi edit ~/.zshrc

# See what changes would be applied
chezmoi diff

# Apply changes
chezmoi apply -v

# Add and apply in one go
chezmoi add --apply ~/.gitconfig
```

### On a new machine
```bash
# Initialize from your GitHub repo
chezmoi init https://github.com/yourusername/dotfiles.git

# Review what will be changed
chezmoi diff

# Apply the dotfiles
chezmoi apply -v

# Or do it all in one command
chezmoi init --apply https://github.com/yourusername/dotfiles.git
```

## Machine-Specific Configuration

Edit `~/.config/chezmoi/chezmoi.toml` to set machine type and other variables.

### Using templates
Files with `.tmpl` extension support Go templating:

```
{{ if eq .machine.type "work" }}
# Work-specific config
{{ else }}
# Personal config
{{ end }}
```

### Using different files per machine
- `file.tmpl` - Template with conditions
- `file_work` - Only on work machines
- `file_personal` - Only on personal machines

Rename files with special prefixes:
- `dot_` prefix becomes `.` (e.g., `dot_zshrc` → `.zshrc`)
- `private_` for files that shouldn't be world-readable
- `executable_` for scripts that should be executable
- `_work` suffix for work machine only
- `_personal` suffix for personal machine only

## Common Workflows

### Update dotfiles
```bash
chezmoi edit ~/.zshrc  # Edit in chezmoi
chezmoi apply          # Apply to home directory
chezmoi cd && git add . && git commit -m "Update zshrc" && git push
```

### Pull updates from another machine
```bash
chezmoi update  # Pulls from git and applies
```

### Add entire directories
```bash
chezmoi add ~/.config/nvim
```
