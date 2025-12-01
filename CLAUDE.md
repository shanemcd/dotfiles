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

This repository uses a multi-layered secrets approach:

1. **Private encrypted secrets repository** (https://github.com/shanemcd/dotfiles-secrets):
   - Added as a git submodule at `external_secrets/`
   - Contains `chezmoi-secrets.toml.age` (encrypted with age) for template variables
   - Contains encrypted dotfiles like gcloud configuration
   - Automatically initialized by chezmoi when cloning with submodules
   - Requires **both** GitHub access AND the age encryption key

2. **Symlink-based encrypted file management**:
   - Encrypted files (e.g., `dot_config/gcloud/encrypted_*.age`) are stored in the secrets submodule
   - Individual file symlinks in the main repo point to files in `external_secrets/`
   - **Key insight**: Chezmoi processes individual file symlinks correctly (but not directory symlinks)
   - Public dotfiles repo contains only symlinks, no encrypted content
   - Example: `dot_config/gcloud/encrypted_credentials.db.age -> ../../external_secrets/dot_config/gcloud/encrypted_credentials.db.age`

3. **Local configuration** (`~/.config/chezmoi/chezmoi.toml`):
   - NOT in git repository
   - Automatically generated from `.chezmoi.toml.tmpl` which decrypts secrets on-the-fly
   - Contains actual secret values for template rendering
   - Machine-specific and never committed

4. **Age encryption key** (`~/.config/chezmoi/key.txt`):
   - Required to decrypt any encrypted files
   - Must be restored from secure backup (1Password, USB) on new machines
   - Public key: `age1wuc38w6748e7l0za4v5paccs9muasjuuqrdqq8npqyxl0dfseclsfh386e`

## Essential Chezmoi Commands

### New Machine Setup

**Option A: Automated with Ansible (recommended)**

```bash
# 1. Install prerequisites
# macOS: brew install chezmoi age ansible-core
# Linux (Fedora/RHEL): sudo dnf install chezmoi age ansible-core

# 2. Ensure 1Password CLI is authenticated
op whoami

# 3. Run the automated setup
ansible-playbook shanemcd.toolbox.dotfiles

# 4. Reload shell
exec zsh
```

The Ansible role automatically fetches the age key from 1Password and handles the entire setup.

**Option B: Manual setup**

```bash
# 1. Install prerequisites
# macOS: brew install chezmoi age
# Linux (Fedora/RHEL): sudo dnf install chezmoi age

# 2. Restore age key from backup (1Password, USB, etc.)
mkdir -p ~/.config/chezmoi
# Copy key.txt to ~/.config/chezmoi/key.txt
chmod 600 ~/.config/chezmoi/key.txt

# 3. One command to bootstrap everything
chezmoi init --apply git@github.com:shanemcd/dotfiles.git
# This automatically:
# - Clones dotfiles repo
# - Initializes external_secrets submodule
# - Generates config with decrypted secrets (via .chezmoi.toml.tmpl)
# - Applies all dotfiles

# 4. Reload shell
exec zsh
```

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
# --init recreates config from template (re-decrypts secrets)
chezmoi update --init
```

### Managing Secrets

```bash
# Edit secrets in the private submodule
cd ~/.local/share/chezmoi/external_secrets
age -d -i ~/.config/chezmoi/key.txt -o chezmoi-secrets.toml chezmoi-secrets.toml.age
vim chezmoi-secrets.toml

# Re-encrypt and push
age -r age1wuc38w6748e7l0za4v5paccs9muasjuuqrdqq8npqyxl0dfseclsfh386e \
    -o chezmoi-secrets.toml.age chezmoi-secrets.toml
rm chezmoi-secrets.toml
git add chezmoi-secrets.toml.age
git commit -m "Update secrets"
git push

# Update main repo to track new submodule commit
cd ~/.local/share/chezmoi
git add external_secrets
git commit -m "Update secrets submodule"
git push

# On other machines: pull and apply
chezmoi update --init  # Pulls both repos and re-generates config with decrypted secrets
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
- `dot_zprofile.tmpl` - Platform-specific profile (Homebrew setup on macOS only)
- `.chezmoi.toml.tmpl` - Template that generates local config, auto-decrypts secrets on-the-fly
- `.chezmoiexternal.toml` - Copies encrypted secrets from the external_secrets submodule to config directory
- `.gitmodules` - Defines the external_secrets submodule (private secrets repo)
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

## Adding New Encrypted Files to Secrets Repo

To add new encrypted files (like additional config directories):

```bash
# 1. Add the encrypted file to the secrets repo
cd ~/.local/share/dotfiles-secrets
chezmoi add --encrypt ~/path/to/file
git add dot_path/to/encrypted_file.age
git commit -m "Add encrypted file"
git push

# 2. Update the submodule in the main repo
cd ~/.local/share/chezmoi
git submodule update --remote external_secrets

# 3. Create symlink in the main repo
cd ~/.local/share/chezmoi
ln -s ../../external_secrets/dot_path/to/encrypted_file.age dot_path/to/encrypted_file.age

# 4. Commit the symlink
git add dot_path/to/encrypted_file.age
git commit -m "Add symlink to encrypted file"
git push
```

**Important**: Always symlink individual FILES, not directories. Chezmoi follows file symlinks but not directory symlinks.

## Automated Setup with Ansible

This repository has an associated Ansible collection at https://github.com/shanemcd/toolbox that provides automated setup and provisioning.

### The `dotfiles` Role

The `shanemcd.toolbox.dotfiles` Ansible role automates the entire dotfiles setup process:

**What it does:**
1. Creates `~/.config/chezmoi` directory with secure permissions (0700)
2. Fetches the age encryption key from 1Password (if not already present)
3. Initializes chezmoi with `chezmoi init --apply --force git@github.com:shanemcd/dotfiles.git`
4. Automatically applies the configuration

**Usage:**
```bash
ansible-playbook shanemcd.toolbox.dotfiles
```

**Requirements:**
- `chezmoi` installed on the target system
- `community.general` Ansible collection for 1Password integration
- 1Password CLI (`op`) installed and authenticated
- 1Password item named "Chezmoi Key" containing the age private key

**How the key is fetched:**
The role uses the `community.general.onepassword_doc` lookup plugin to securely retrieve the age key from 1Password. This eliminates the manual step of restoring the key from backup during new machine setup.

## When Making Changes

1. **Never edit files in `~/` directly** - they'll be overwritten by `chezmoi apply`
2. **Always use `chezmoi edit <file>`** or edit in `~/.local/share/chezmoi/`
3. **Test with `chezmoi diff`** before applying
4. **Consider both platforms** - changes to `.tmpl` files affect macOS and Linux
5. **Secrets workflow**:
   - Template variables (like project IDs) live in `external_secrets/chezmoi-secrets.toml.age`
   - Encrypted files (like gcloud config) live in the `external_secrets/` submodule with symlinks in main repo
   - Never commit actual secret values or encrypted content to the public dotfiles repo
   - Document new secret variables in `.chezmoi.toml.tmpl` as placeholders (in the fallback section)
   - After updating secrets in the submodule, commit both the submodule change AND the parent repo's submodule reference
6. **Template-based decryption** - `.chezmoi.toml.tmpl` automatically decrypts secrets when chezmoi processes it (no manual steps needed)
7. **Submodule management** - Chezmoi automatically initializes the `external_secrets` submodule on first `chezmoi init`
