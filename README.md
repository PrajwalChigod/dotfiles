# Dotfiles
Personal dotfiles managed with GNU Stow

## Packages

Each top-level directory is a Stow package:

| Package | Deploys |
|---|---|
| `aerospace` | AeroSpace window manager config |
| `bat` | bat config |
| `fish` | Fish shell config and plugin list |
| `ghostty` | Ghostty terminal config, themes, shaders |
| `neovide` | Neovide (Neovim GUI) config |
| `starship` | Starship prompt config |
| `tmux` | `~/.tmux.conf` |
| `wezterm` | WezTerm terminal config |
| `zsh` | `~/.zshrc` |

## Tools to Install

The following packages need to be installed for the configurations to work properly:

- **stow**: Symlink farm manager (deploys these dotfiles)
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
- **neovim**: Editor (used by the `nv` alias and the worktree helpers in the fish config)
- **neovide**: Neovim GUI
- **aerospace**: Aerospace window manager for macos
- **rustup**: Rust toolchain (fish sources `~/.cargo/env.fish`)
- **IoskeleyMono Nerd Font**: Font used by ghostty and wezterm

Install all tools:
```bash
brew install stow eza fzf bat fish zsh tmux ghostty wezterm starship lazygit pyenv neovim neovide rustup
brew install --cask nikitabobko/tap/aerospace
brew install --cask font-ioskeley-mono-term-nerd-font
```

> The ghostty and wezterm configs expect the font family `IoskeleyMono Nerd Font`.
> If the cask above installs it under a different family name, update `font-family`
> in `ghostty/.config/ghostty/config` and `config.font` in `wezterm/.config/wezterm/wezterm.lua`.

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
Need not be this location as mentioned above. You can set this up in any location you wish.

### 2. Install required packages
See [Tools to Install](#tools-to-install) above and run the install commands there.

After installing `rustup`, initialise the toolchain (this creates `~/.cargo/env.fish`):
```bash
rustup-init
```

### 3. Backup and remove existing dotfiles
Stow will refuse to create a symlink if the target file already exists. Back up and remove
any existing configs for the packages you are about to stow:

```bash
mkdir -p ~/dotfiles-backup

# Files in the home directory (zsh, tmux)
cp ~/.zshrc ~/.tmux.conf ~/dotfiles-backup/ 2>/dev/null || true
rm -f ~/.zshrc ~/.tmux.conf

# Folders in ~/.config (one per package: aerospace, bat, fish, ghostty, neovide, starship, wezterm)
for app in aerospace bat fish ghostty neovide wezterm; do
  [ -e ~/.config/$app ] && cp -R ~/.config/$app ~/dotfiles-backup/
done
cp ~/.config/starship.toml ~/dotfiles-backup/ 2>/dev/null || true

rm -rf ~/.config/{aerospace,bat,fish,ghostty,neovide,wezterm}
rm -f ~/.config/starship.toml
```

### 4. Deploy dotfiles using Stow

If your git managed dotfiles is not a parent directory,
for ex:
instead of ~/dotfiles/ , If you have structure like ~/some_dirname/dotfiles/
then your stow command needs to be
```bash
stow -d ~/projects/dotfiles -t ~ appname
```

```bash
# From the dotfiles directory, run:
stow zsh
stow fish
stow tmux
stow bat
stow ghostty
stow starship
stow wezterm
stow aerospace
stow neovide
```

> Do not use `stow */` here: it would also stow any other directory in the repo that is not
> meant to be deployed on every machine.

Note: `fish/.stow-local-ignore` skips `functions/`, `conf.d/`, `completions/`, `themes/` and
`fish_variables` because Fisher generates them. They are created in step 5, not by Stow.

### 5. Set up Fish shell (if using Fish)
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

# Install every plugin listed in fish/.config/fish/fish_plugins
fisher update
```

The plugins in `fish_plugins` are:

- `jorgebucaran/fisher`
- `patrickf1/fzf.fish`
- `jethrokuan/z`
- `jorgebucaran/autopair.fish`
- `patrickf1/colored_man_pages.fish`
- `catppuccin/fish`
- `meaningful-ooo/sponge`

### 6. Set up tmux plugins
tmux plugins are managed by [TPM](https://github.com/tmux-plugins/tpm), which `.tmux.conf` loads from `~/.tmux/plugins/tpm`.

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Start tmux and press `prefix + I` (capital i) to install the plugins:

- `christoomey/vim-tmux-navigator`
- `tmux-plugins/tmux-resurrect`
- `tmux-plugins/tmux-continuum`
- `tmux-plugins/tmux-sessionist`

### 7. Verify installation
Check that symlinks are created:
```bash
ls -la ~/.zshrc ~/.tmux.conf
ls -la ~/.config/{aerospace,bat,fish,ghostty,neovide,wezterm} ~/.config/starship.toml
```
You should see symlinks (`->`) pointing to your dotfiles repo.

## Managing Dotfiles


### Add new config
1. Create directory structure: `mkdir -p appname/.config/appname`
2. Copy config file maintaining home directory structure
3. Run: `stow appname`
4. Add it to the [Packages](#packages) table, [Tools to Install](#tools-to-install) and the stow list in step 4

### Remove config
```bash
stow -D appname
```

### Update config
Just edit the files in this repo - changes reflect immediately via symlinks
