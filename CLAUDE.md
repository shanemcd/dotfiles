# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a chezmoi-managed dotfiles repository that synchronizes shell configuration, environment variables, and system settings across macOS and Linux machines. The repository uses templating to handle platform-specific configurations and secrets management.

## Key Architecture Concepts

### Chezmoi Source Directory vs Target Directory

- **Source directory**: `~/.local/share/chezmoi/` - This is the git repository where you edit files
- **Target directory**: `~/` (home directory) - Where chezmoi applies the processed files
- Files in the source directory use special naming conventions that determine how they're processed and where they're installed

### File Naming Conventions

Chezmoi uses prefixes to control file processing:

- `dot_` → Creates a dotfile (e.g., `dot_zshrc` → `~/.zshrc`)
- `.tmpl` suffix → Processes as a Go template before applying (e.g., `dot_zshrc.tmpl` → `~/.zshrc` with templates rendered)
- `encrypted_` → Encrypted file requiring age key (e.g., `encrypted_dot_zshrc_private.age` → `~/.zshrc_private`)
- `executable_` → Sets executable permissions
- `private_` → Sets restrictive permissions (chmod 600)

### Template System

Files with `.tmpl` extension are processed as Go templates with access to:

- `.chezmoi.os` - Operating system ("darwin" for macOS, "linux" for Linux)
- `.secrets.*` - Variables from `~/.config/chezmoi/chezmoi.toml` under `[data.secrets]`
- `.machine.*` - Machine-specific configuration from the config file

Example from `dot_zshrc.tmpl`:
```
{{- if eq .chezmoi.os "darwin" }}
# macOS-specific configuration
{{- else }}
# Linux-specific configuration
{{- end }}

export ANTHROPIC_VERTEX_PROJECT_ID={{ .secrets.anthropic_vertex_project_id }}
```

### Secrets Management Architecture

This repository uses a hybrid approach:

1. **Local configuration** (`~/.config/chezmoi/chezmoi.toml`):
   - NOT in git repository
   - Contains machine-specific values and secrets
   - Must be manually created on each new machine from `.chezmoi.toml.tmpl`

2. **Age encryption** (optional):
   - Encrypted files use age encryption and ARE committed to git
   - Requires `~/.config/chezmoi/key.txt` to decrypt
   - Example: `encrypted_dot_zshrc_private.age`

3. **External dependencies** (`.chezmoiexternal.toml`):
   - Template for pulling files from external repos
   - Currently contains only examples

## Essential Chezmoi Commands

### Development Workflow

```bash
# Edit a managed file (ALWAYS use this, not direct editing)
chezmoi edit ~/.zshrc

# Preview what changes will be applied
chezmoi diff

# Apply changes from source directory to home directory
chezmoi apply -v

# Add a new file to chezmoi management
chezmoi add ~/.newfile
```

### Working in Source Directory

```bash
# Navigate to the source directory
chezmoi cd

# Make changes, commit, and return home
git add .
git commit -m "Update config"
git push
exit
```

### Syncing Across Machines

```bash
# Pull latest changes from git and apply
chezmoi update
```

### Debugging and Verification

```bash
# See all files managed by chezmoi
chezmoi managed

# Check how a template will be rendered
chezmoi execute-template < ~/.local/share/chezmoi/dot_zshrc.tmpl

# View current configuration data
chezmoi data
```

## Platform-Specific Behavior

The repository handles macOS and Linux differently:

### macOS-specific features (`dot_zshrc.tmpl`):
- Homebrew path management (`/opt/homebrew/bin`)
- iTerm2 integration (line 161-163)
- Bun JavaScript runtime setup
- Tinty theme auto-switching based on system dark mode
- fzf installed via Homebrew

### Linux-specific features:
- Krew (kubectl plugin manager) in PATH
- Podman aliases and socket configuration for toolbox environments
- fzf from system packages (`/usr/share/fzf/shell/key-bindings.zsh`)
- Hardcoded username path in some locations (line 141, 148)

## Critical Files

- `dot_zshrc.tmpl` - Main shell configuration, extensively templated for cross-platform use
- `.chezmoi.toml.tmpl` - Template for local config file, defines required secrets structure
- `.chezmoiignore` - Files managed by chezmoi but not committed to git
- `.gitignore` - Prevents committing private dotfiles to the repository
- `encrypted_dot_zshrc_private.age` - Encrypted private shell configuration (requires age key)

## Environment Variables and Secrets

The following secrets are required in `~/.config/chezmoi/chezmoi.toml`:

```toml
[data.secrets]
    anthropic_vertex_project_id = "your-project-id"
    google_cloud_project = "your-project-id"
```

These are referenced in `dot_zshrc.tmpl` and exported as environment variables for Claude Code and Google Cloud SDK integration.

## Common Modifications

### Adding a new dotfile:
```bash
# Add the file
chezmoi add ~/.gitconfig

# If it needs templating, rename in source directory
cd ~/.local/share/chezmoi
mv dot_gitconfig dot_gitconfig.tmpl
# Edit to add template variables
chezmoi apply -v
```

### Adding machine-specific configuration:
1. Add variable to `.chezmoi.toml.tmpl` as documentation
2. Use in templates with `{{ .secrets.variable_name }}` or `{{ .machine.variable_name }}`
3. Users must add actual values to their local `~/.config/chezmoi/chezmoi.toml`

### Adding platform-specific code:
Use conditional blocks in `.tmpl` files:
```
{{- if eq .chezmoi.os "darwin" }}
# macOS code
{{- else if eq .chezmoi.os "linux" }}
# Linux code
{{- end }}
```

## When Making Changes

1. **Never edit files in `~/` directly** - they'll be overwritten by `chezmoi apply`
2. **Always use `chezmoi edit <file>`** or edit in `~/.local/share/chezmoi/`
3. **Test with `chezmoi diff`** before applying
4. **Consider both platforms** - changes to `.tmpl` files affect macOS and Linux
5. **Secrets go in local config** - never commit secrets to `.tmpl` files
6. **Document new secrets** - add examples to `.chezmoi.toml.tmpl` for other users
