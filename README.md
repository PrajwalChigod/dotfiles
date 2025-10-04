# Dotfiles
Personal dotfiles managed with GNU Stow

## Tools to Install

The following packages need to be installed for the configurations to work properly:

- **eza**: Modern replacement for ls
- **fzf**: Fuzzy finder
- **bat**: Cat clone with syntax highlighting
- **fish**: Fish shell
- **zsh**: Z shell
- **tmux**: Terminal multiplexer
- **ghostty**: Terminal emulator
- **wezterm**: Terminal emulator
- **starship**: Cross-shell prompt
- **lazygit**: Terminal UI for git
- **pyenv**: Python version manager

Install all tools:
```bash
brew install eza fzf bat fish zsh tmux ghostty wezterm starship lazygit pyenv
```

## If You Already Have Existing Dotfiles

If your configs already exist in your home directory:

1. **Backup your current configs**:
   ```bash
   mkdir -p ~/.config/backups/pre-stow
   cp ~/.zshrc ~/.tmux.conf ~/.config/backups/pre-stow/ 2>/dev/null || true
   cp ~/.config/starship.toml ~/.config/backups/pre-stow/ 2>/dev/null || true
   ```

2. **Remove existing configs**:
   ```bash
   rm ~/.zshrc ~/.tmux.conf ~/.config/starship.toml
   ```

3. **Then proceed with stow** (see step 5 below)

## What's Included

- **zsh**: Z shell configuration
- **fish**: Fish shell configuration
- **tmux**: Terminal multiplexer configuration
- **bat**: Cat clone with syntax highlighting
- **ghostty**: Terminal emulator configuration
- **wezterm**: Terminal emulator configuration
- **starship**: Cross-shell prompt

## Prerequisites

Install Homebrew (if not already installed):
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## Installation on a New System

### 1. Clone this repository
```bash
git clone https://github.com/PrajwalChigod/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 2. Install required packages
```bash
# Install GNU Stow
brew install stow

# Install all applications
brew install eza fzf bat fish zsh tmux ghostty wezterm starship lazygit pyenv
```

### 3. Backup and remove existing dotfiles
```bash
# Backup existing configs (optional but recommended)
mkdir -p ~/dotfiles-backup
cp ~/.zshrc ~/dotfiles-backup/ 2>/dev/null || true
cp ~/.tmux.conf ~/dotfiles-backup/ 2>/dev/null || true
cp -r ~/.config/fish ~/dotfiles-backup/ 2>/dev/null || true
cp -r ~/.config/bat ~/dotfiles-backup/ 2>/dev/null || true
cp -r ~/.config/ghostty ~/dotfiles-backup/ 2>/dev/null || true
cp -r ~/.config/wezterm ~/dotfiles-backup/ 2>/dev/null || true
cp ~/.config/starship.toml ~/dotfiles-backup/ 2>/dev/null || true

# Remove existing configs (stow will fail if these exist)
rm -f ~/.zshrc ~/.tmux.conf ~/.config/starship.toml
rm -rf ~/.config/fish ~/.config/bat ~/.config/ghostty ~/.config/wezterm
```

### 4. Set up Fish shell (if using Fish)
```bash
# Find the fish path
which fish

# Add fish to allowed shells
echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells

# Change default shell to fish
chsh -s /opt/homebrew/bin/fish

# Restart terminal and verify
echo $SHELL

# Install fisher (fish plugin manager)
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher

# Install all fish essential plugins
fisher install PatrickF1/fzf.fish
fisher install jethrokuan/z
fisher install jorgebucaran/autopair.fish
fisher install franciscolourenco/done
fisher install nickeb96/puffer-fish
fisher install PatrickF1/colored_man_pages.fish
fisher install jhillyerd/plugin-git

```

### 5. Deploy dotfiles using Stow
```bash
# From the dotfiles directory, run:
stow zsh
stow fish
stow tmux
stow bat
stow ghostty
stow starship
stow wezterm

# Or deploy all at once:
stow */
```

### 6. Verify installation
Check that symlinks are created:
```bash
ls -la ~/.zshrc ~/.tmux.conf
ls -la ~/.config/fish ~/.config/starship.toml
```
You should see symlinks (`->`) pointing to your dotfiles repo.

## Managing Dotfiles

### Add new config
1. Create directory structure: `mkdir -p appname/.config/appname`
2. Copy config file maintaining home directory structure
3. Run: `stow appname`

### Remove config
```bash
stow -D appname
```

### Update config
Just edit the files in this repo - changes reflect immediately via symlinks
