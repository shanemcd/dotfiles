# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/), supporting both macOS and Linux (Fedora/RHEL). Features encrypted secrets management using age, cross-platform templating, and automated setup via Ansible.

## Bootstrapping a New Machine

Two options: automated (recommended) or manual.

### Option A: Automated Setup with Ansible

This is the easiest way to get everything configured on a new machine.

**Prerequisites:**
- macOS: `brew install chezmoi age ansible-core`
- Linux (Fedora): `sudo dnf install chezmoi age ansible-core`
- 1Password CLI authenticated (`op whoami` should work)

**Run the setup:**
```bash
ansible-playbook shanemcd.toolbox.dotfiles
exec zsh  # Reload shell
```

The [shanemcd.toolbox](https://github.com/shanemcd/toolbox) Ansible collection automatically:
- Creates `~/.config/chezmoi` with secure permissions
- Fetches the age key from 1Password (from the "Chezmoi Key" item)
- Clones the dotfiles repo and initializes the secrets submodule
- Decrypts secrets via `.chezmoi.toml.tmpl`
- Applies all configuration

### Option B: Manual Setup

If you prefer manual control or don't have Ansible set up yet.

**Prerequisites:**
- macOS: `brew install chezmoi age`
- Linux (Fedora): `sudo dnf install chezmoi age`

**Setup steps:**

1. **Initialize and apply:**
   ```bash
   chezmoi init --apply git@github.com:shanemcd/dotfiles.git
   ```

   This automatically:
   - Clones the dotfiles repository
   - Initializes the `external_secrets` submodule (private repo with encrypted secrets)
   - Prompts for the age private key if not already present (paste from 1Password)
   - Writes the key to `~/.config/chezmoi/key.txt` with secure permissions
   - Generates `~/.config/chezmoi/chezmoi.toml` from `.chezmoi.toml.tmpl` (which decrypts secrets on-the-fly)
   - Applies all dotfiles to your home directory

2. **Reload the shell:**
   ```bash
   exec zsh
   ```

Done! Environment configured.

---

## How This Works

### Architecture Overview

This setup uses chezmoi with several key features:

- **Cross-platform templates**: Files ending in `.tmpl` use Go templates to handle macOS vs Linux differences
- **Encrypted secrets**: Sensitive data is encrypted with age and stored in a private git submodule
- **Template-based decryption**: `.chezmoi.toml.tmpl` automatically decrypts secrets when chezmoi processes it
- **Symlinked encrypted files**: Individual encrypted files (like gcloud config) are symlinked from the private submodule

### Secrets Management

**Three-layer approach:**

1. **Private encrypted repository** ([dotfiles-secrets](https://github.com/shanemcd/dotfiles-secrets)):
   - Git submodule at `external_secrets/`
   - Contains `chezmoi-secrets.toml.age` (encrypted template variables)
   - Contains encrypted dotfiles like `~/.config/gcloud/credentials.db`
   - Requires both GitHub access AND the age encryption key

2. **Template-based decryption** (`.chezmoi.toml.tmpl`):
   - Automatically decrypts secrets when chezmoi generates config
   - Uses `output "age" ...` to decrypt on-the-fly
   - Falls back to placeholder values if key is missing

3. **Age encryption key** (`~/.config/chezmoi/key.txt`):
   - Required to decrypt all secrets
   - Automatically prompted during `chezmoi init` if not present
   - Public key: `age1wuc38w6748e7l0za4v5paccs9muasjuuqrdqq8npqyxl0dfseclsfh386e`
   - Backed up in 1Password (item: "Chezmoi Key")

**Security model:**
- Encrypted with age (secure even if GitHub is compromised)
- Private repository (not publicly visible)
- Requires **both** GitHub access AND encryption key

---

## Day-to-Day Usage

### Making Changes

```bash
# Edit a managed file
chezmoi edit ~/.zshrc

# Or edit directly in the source directory
vim ~/.local/share/chezmoi/dot_zshrc.tmpl

# Preview what will change
chezmoi diff

# Apply changes
chezmoi apply -v

# Add a new file to chezmoi
chezmoi add ~/.gitconfig
```

### Syncing Changes Across Machines

**On machine A (where you made changes):**
```bash
chezmoi cd
git add .
git commit -m "Update zsh config"
git push
exit
```

**On machine B (pulling changes):**
```bash
chezmoi update --init  # Pulls, regenerates config, applies
```

The `--init` flag is important—it recreates `~/.config/chezmoi/chezmoi.toml` from the template, ensuring secrets are re-decrypted.

---

## Updating Secrets

When you need to add or change secrets (API keys, project IDs, etc.):

```bash
# 1. Navigate to secrets submodule
cd ~/.local/share/chezmoi/external_secrets

# 2. Decrypt secrets
age -d -i ~/.config/chezmoi/key.txt -o chezmoi-secrets.toml chezmoi-secrets.toml.age

# 3. Edit your secrets
vim chezmoi-secrets.toml

# 4. Re-encrypt
age -r age1wuc38w6748e7l0za4v5paccs9muasjuuqrdqq8npqyxl0dfseclsfh386e \
    -o chezmoi-secrets.toml.age chezmoi-secrets.toml

# 5. Clean up and commit to secrets repo
rm chezmoi-secrets.toml
git add chezmoi-secrets.toml.age
git commit -m "Update secrets"
git push

# 6. Update main dotfiles repo to track new submodule commit
cd ~/.local/share/chezmoi
git add external_secrets
git commit -m "Update secrets submodule"
git push

# 7. Update on other machines
chezmoi update --init
```

---

## Platform-Specific Features

### macOS
- Homebrew path management (`/opt/homebrew/bin`)
- iTerm2 shell integration
- Bun JavaScript runtime
- Tinty theme auto-switching based on system dark mode
- fzf via Homebrew

### Linux (Fedora/RHEL)
- Krew (kubectl plugin manager) in PATH
- Podman aliases and socket configuration for toolbox environments
- fzf from system packages

---

## Troubleshooting

**Check what chezmoi will do:**
```bash
chezmoi diff
```

**See what files are managed:**
```bash
chezmoi managed
```

**Verify template rendering:**
```bash
chezmoi execute-template < ~/.local/share/chezmoi/dot_zshrc.tmpl
```

**View current configuration data:**
```bash
chezmoi data
```

**Force re-apply everything:**
```bash
chezmoi apply --force
```

---

## More Information

For detailed technical documentation, architecture decisions, and development guidelines, see [CLAUDE.md](CLAUDE.md).

For the Ansible automation code, see [shanemcd/toolbox](https://github.com/shanemcd/toolbox).
