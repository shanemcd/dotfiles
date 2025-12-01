# Dotfiles managed with chezmoi

## Quick Start - New Machine Setup

This repo uses encrypted secrets in a private GitHub repository for automatic sync across machines.

**Prerequisites:**
- macOS: `brew install chezmoi age`
- Linux (Fedora/RHEL): `sudo dnf install chezmoi age`
- Linux (Debian/Ubuntu): `sudo apt install chezmoi age`

**Setup Steps:**

1. **Restore your age key first:**
   ```bash
   mkdir -p ~/.config/chezmoi
   # Copy key.txt from your secure backup (1Password, USB, etc.)
   chmod 600 ~/.config/chezmoi/key.txt
   ```

2. **One command to bootstrap everything:**
   ```bash
   chezmoi init --apply git@github.com:shanemcd/dotfiles.git
   ```

   This automatically:
   - Clones your dotfiles repository
   - Initializes the secrets submodule
   - Copies encrypted secrets file to `~/.config/chezmoi/`
   - Generates config with decrypted secrets (via `.chezmoi.toml.tmpl`)
   - Applies all dotfiles

3. **Reload your shell:**
   ```bash
   exec zsh
   ```

Done! Your environment variables and dotfiles are configured.

**Note:** If you don't have the age key in step 1, chezmoi will still initialize but skip decryption. You can add the key later and run `chezmoi apply -v` to complete setup.

---

## How Secrets Work

**This repo uses encrypted secrets in a private git submodule:**

✅ **Encrypted private repository** (https://github.com/shanemcd/dotfiles-secrets):
- Contains `chezmoi-secrets.toml.age` (encrypted with age)
- Managed as a git submodule at `external_secrets/`
- Automatically initialized by chezmoi on first run
- Stores all secrets: GCP project IDs, API keys, etc.

✅ **Age encryption key** (`~/.config/chezmoi/key.txt`):
- Required to decrypt secrets
- Must be backed up securely (1Password, USB, etc.)
- Public key: `age1wuc38w6748e7l0za4v5paccs9muasjuuqrdqq8npqyxl0dfseclsfh386e`

✅ **Template-based decryption** (`.chezmoi.toml.tmpl`):
- Automatically decrypts secrets when chezmoi processes the config template
- Decrypts `chezmoi-secrets.toml.age` on-the-fly and injects into `~/.config/chezmoi/chezmoi.toml`
- Gracefully handles missing age key with placeholder values

**Security layers:**
- ✅ Encrypted with age (secure even if GitHub is compromised)
- ✅ Private repository (not publicly visible)
- ✅ Requires both GitHub access AND encryption key

---

## Updating Secrets

When you need to add or change secrets (API keys, project IDs, etc.):

```bash
# 1. Navigate to the secrets submodule
cd ~/.local/share/chezmoi/external_secrets

# 2. Decrypt the secrets file
age -d -i ~/.config/chezmoi/key.txt -o chezmoi-secrets.toml chezmoi-secrets.toml.age

# 3. Edit your secrets
vim chezmoi-secrets.toml

# 4. Re-encrypt
age -r age1wuc38w6748e7l0za4v5paccs9muasjuuqrdqq8npqyxl0dfseclsfh386e \
    -o chezmoi-secrets.toml.age chezmoi-secrets.toml

# 5. Clean up and commit
rm chezmoi-secrets.toml
git add chezmoi-secrets.toml.age
git commit -m "Update secrets"
git push

# 6. Update the main dotfiles repo to track the new submodule commit
cd ~/.local/share/chezmoi
git add external_secrets
git commit -m "Update secrets submodule"
git push

# 7. Update on all your other machines
chezmoi update  # Pulls both repos and re-generates config with decrypted secrets
```

---

## Daily Usage

### Making changes to dotfiles

```bash
# Edit a managed file (recommended)
chezmoi edit ~/.zshrc

# Or edit directly in the repo
vim ~/.local/share/chezmoi/dot_zshrc.tmpl

# Preview changes before applying
chezmoi diff

# Apply changes to your home directory
chezmoi apply -v

# Add a new file to chezmoi
chezmoi add ~/.gitconfig
```

### Syncing changes across machines

```bash
# On machine A: Push changes
chezmoi cd
git add .
git commit -m "Update zsh config"
git push
exit  # Return to home directory

# On machine B: Pull changes
chezmoi update  # Pulls from git and applies
```

### Adding new dotfiles

```bash
# Add a single file
chezmoi add ~/.tmux.conf

# Add an entire directory
chezmoi add ~/.config/nvim

# Add and apply immediately
chezmoi add --apply ~/.vimrc
```



## Quick Reference

### Key Directories

```
~/.local/share/chezmoi/          # Git repo (edit here, push to GitHub)
~/.config/chezmoi/chezmoi.toml   # Local config with secrets (NEVER in git)
~/.config/chezmoi/key.txt        # Age encryption key (NEVER in git)
~/                               # Managed dotfiles (applied by chezmoi)
```

### Essential Commands

```bash
chezmoi init <repo>              # Clone dotfiles repo
chezmoi diff                     # Preview changes
chezmoi apply -v                 # Apply dotfiles to home directory
chezmoi edit <file>              # Edit a managed file
chezmoi add <file>               # Add a new file to chezmoi
chezmoi update                   # Pull from git and apply
chezmoi cd                       # Go to source directory
```

### File Naming Conventions

```
dot_zshrc.tmpl         → ~/.zshrc (template processed)
dot_zshrc              → ~/.zshrc (copied as-is)
encrypted_dot_foo.age  → ~/.foo (encrypted, requires age key)
executable_script      → ~/script (with execute permissions)
private_dot_ssh_config → ~/.ssh/config (chmod 600)
```

### Troubleshooting

**Check what chezmoi will do:**
```bash
chezmoi diff
```

**Force re-apply everything:**
```bash
chezmoi apply --force
```

**See what files chezmoi manages:**
```bash
chezmoi managed
```

**Verify templates render correctly:**
```bash
chezmoi execute-template < ~/.local/share/chezmoi/dot_zshrc.tmpl
```

**Check configuration:**
```bash
chezmoi data
```
