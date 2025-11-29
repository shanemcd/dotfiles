# Dotfiles managed with chezmoi

## Setting Up a New Machine

### Step 1: Install chezmoi

**macOS:**
```bash
brew install chezmoi age
```

**Linux (Fedora/RHEL):**
```bash
sudo dnf install chezmoi age
```

**Linux (Debian/Ubuntu):**
```bash
sudo apt install chezmoi age
```

### Step 2: Clone your dotfiles

```bash
# Initialize from GitHub
chezmoi init https://github.com/yourusername/dotfiles.git
```

This creates `~/.local/share/chezmoi` with your dotfiles.

### Step 3: Configure machine-specific settings

```bash
# Copy the config template
cp ~/.local/share/chezmoi/.chezmoi.toml.tmpl ~/.config/chezmoi/chezmoi.toml

# Edit the config file
vim ~/.config/chezmoi/chezmoi.toml
```

**Required changes:**
- Set `email` and `name`
- Set `type = "mac"` or `type = "linux"`
- Add your secrets to `[data.secrets]` section

**Optional (if using encrypted files):**
- Copy your age encryption key to `~/.config/chezmoi/key.txt`
- Set correct `recipient` in the `[age]` section
- Uncomment `encryption = "age"`

### Step 4: Preview changes

```bash
# See what files will be created/modified
chezmoi diff
```

### Step 5: Apply dotfiles

```bash
# Apply all changes
chezmoi apply -v
```

### Step 6: Restart your shell

```bash
# Reload zsh configuration
exec zsh
```

Done! Your new machine is configured.

---

## One-Command Setup (Advanced)

If you have your secrets ready and age key available:

```bash
# Install chezmoi and apply in one go
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply yourusername/dotfiles

# Then configure secrets
cp ~/.local/share/chezmoi/.chezmoi.toml.tmpl ~/.config/chezmoi/chezmoi.toml
vim ~/.config/chezmoi/chezmoi.toml  # Add your secrets
chezmoi apply -v
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

## Managing Secrets

Sensitive data (API keys, project IDs, etc.) should never be committed to git unencrypted. Chezmoi provides several approaches:

### Approach 1: Local Config Only (Simplest) ⭐ RECOMMENDED

**Best for:** Most users, simple setups

Store secrets in `~/.config/chezmoi/chezmoi.toml` (NOT in git):

```toml
[data.secrets]
    anthropic_vertex_project_id = "my-gcp-project"
    google_cloud_project = "my-gcp-project"
```

Reference in templates (`dot_zshrc.tmpl`):
```bash
export ANTHROPIC_VERTEX_PROJECT_ID={{ .secrets.anthropic_vertex_project_id }}
export GOOGLE_CLOUD_PROJECT={{ .secrets.google_cloud_project }}
```

**When you provision a new machine:**
1. Clone dotfiles
2. Copy config template: `cp ~/.local/share/chezmoi/.chezmoi.toml.tmpl ~/.config/chezmoi/chezmoi.toml`
3. Edit and add your secrets
4. Apply: `chezmoi apply`

**Pros:** Simple, secure, easy to understand
**Cons:** Must manually configure on each new machine (but that's usually good!)

### Approach 2: Encrypted Secrets in Private Repo ⭐ ACTIVE

**Best for:** Users who want secrets backed up, synced, AND encrypted

This repo uses an encrypted private repository for secrets management.

**Setup (already configured):**
- Age encryption key at `~/.config/chezmoi/key.txt`
- Private repo: https://github.com/shanemcd/dotfiles-secrets
- Encrypted config: `chezmoi-secrets.toml.age` (pulled via git-repo in `.chezmoiexternal.toml`)

**When you provision a new machine:**

1. **Transfer your encryption key first** (via USB, 1Password, secure backup)
   ```bash
   # Copy key to new machine
   mkdir -p ~/.config/chezmoi
   # Copy key.txt from your secure backup
   chmod 600 ~/.config/chezmoi/key.txt
   ```

2. **Clone and apply dotfiles**:
   ```bash
   chezmoi init git@github.com:shanemcd/dotfiles.git
   ```

   This will:
   - Clone your main dotfiles to `~/.local/share/chezmoi`
   - Clone your secrets repo to `~/.local/share/dotfiles-secrets` (via `.chezmoiexternal.toml`)
   - Copy encrypted `chezmoi-secrets.toml.age` to `~/.config/chezmoi/`

3. **Decrypt secrets to create your local config**:
   ```bash
   age -d -i ~/.config/chezmoi/key.txt \
       -o ~/.config/chezmoi/chezmoi.toml \
       ~/.config/chezmoi/chezmoi-secrets.toml.age
   ```

4. **Apply dotfiles**:
   ```bash
   chezmoi apply -v
   ```

**Updating secrets:**

```bash
# 1. Navigate to the secrets repo (already cloned by chezmoi)
cd ~/.local/share/dotfiles-secrets

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

# 6. Update on all your machines
cd ~/.local/share/dotfiles-secrets && git pull  # Pull latest secrets
age -d -i ~/.config/chezmoi/key.txt \
    -o ~/.config/chezmoi/chezmoi.toml \
    chezmoi-secrets.toml.age  # Update local config
chezmoi apply  # Apply changes
```

**Security layers:**
- ✅ Encrypted with age (secure even if GitHub is compromised)
- ✅ Private repository (not publicly visible)
- ✅ Requires both GitHub access AND encryption key

**Pros:** Best security, automatic sync, backed up
**Cons:** More complex setup, need to manage encryption key

### Approach 3: External Private Repo (Unencrypted - Not Recommended)

**Best for:** Teams, work environments with shared secrets

Pull secrets from a separate private GitHub repo (see `.chezmoiexternal.toml` for template).

**When you provision a new machine:**
1. Ensure you have access to the private secrets repo
2. Set up GitHub authentication (SSH key or token)
3. `chezmoi init --apply` pulls both dotfiles and secrets automatically

---

## How This Repo Uses Secrets

**This repo uses Approach 2: Encrypted Secrets in Private Repo**

✅ **Encrypted private repository** (https://github.com/shanemcd/dotfiles-secrets):
- Contains `chezmoi-secrets.toml.age` (encrypted with age)
- Cloned to `~/.local/share/dotfiles-secrets` via `.chezmoiexternal.toml` (git-repo type)
- Stores all secrets: GCP project IDs, API keys, etc.

✅ **Age encryption key** (`~/.config/chezmoi/key.txt`):
- Required to decrypt secrets
- Must be backed up securely (1Password, USB, etc.)
- Public key: `age1wuc38w6748e7l0za4v5paccs9muasjuuqrdqq8npqyxl0dfseclsfh386e`

**To provision a new machine:**

1. **Restore your age key first:**
   ```bash
   mkdir -p ~/.config/chezmoi
   # Copy key.txt from your secure backup
   chmod 600 ~/.config/chezmoi/key.txt
   ```

2. **Init and setup** (one command):
   ```bash
   chezmoi init git@github.com:shanemcd/dotfiles.git
   ~/.local/share/chezmoi/setup-secrets.sh
   chezmoi apply -v
   ```

   The `setup-secrets.sh` helper script automatically:
   - Checks for your age key
   - Decrypts `chezmoi-secrets.toml.age`
   - Creates your local `chezmoi.toml` config

**Alternative manual steps:**
```bash
# If you prefer to do it manually:
chezmoi init git@github.com:shanemcd/dotfiles.git
age -d -i ~/.config/chezmoi/key.txt \
    -o ~/.config/chezmoi/chezmoi.toml \
    ~/.config/chezmoi/chezmoi-secrets.toml.age
chezmoi apply -v
```

---

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
