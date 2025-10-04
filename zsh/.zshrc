# ~/.zshrc

# Oh-My-Zsh
export ZSH="$HOME/.oh-my-zsh"
plugins=(git zsh-autosuggestions)
source $ZSH/oh-my-zsh.sh

# PATH
export PATH=/usr/local/bin:$PATH
export PATH=~/.npm-global/bin:$PATH
export PATH="$HOME/bin:$PATH"

# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"

# Aliases
alias ls="eza --tree --level=1 --icons"
alias ls2="eza --tree --level=2 --icons"
alias ls3="eza --tree --level=3 --icons"
alias ls4="eza --tree --level=4 --icons"
alias lso="eza --oneline"
alias claude="npx @anthropic-ai/claude-code"
alias gg="lazygit"

# Git worktree helper
gwa() {
  new_branch="$1"
  base_branch="${2:-origin/main}"
  mkdir -p .worktree
  git worktree add ".worktree/$new_branch" -b "$new_branch" "$base_branch"
}

# Git worktree checkout
gwc() {
  branch="$1"
  worktree_path=".worktree/$branch"

  if [ ! -d "$worktree_path" ]; then
    echo "Error: Worktree branch '$branch' does not exist at $worktree_path"
    return 1
  fi

  cd "$worktree_path"
}

# Git worktree list
gwl() {
  git worktree list
}

# Git worktree remove
gwr() {
  branch="$1"
  worktree_path=".worktree/$branch"

  if [ ! -d "$worktree_path" ]; then
    echo "Error: Worktree branch '$branch' does not exist at $worktree_path"
    return 1
  fi

  git worktree remove "$worktree_path"
}

# Starship prompt (must be last)
eval "$(starship init zsh)"
