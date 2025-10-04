# HOMEBREW
eval (/opt/homebrew/bin/brew shellenv)

fish_add_path /usr/local/bin
fish_add_path ~/.npm-global/bin
fish_add_path ~/bin

# PYENV
set -gx PYENV_ROOT "$HOME/.pyenv"
fish_add_path $PYENV_ROOT/bin
pyenv init - | source

# STARSHIP PROMPT
starship init fish | source

# ALIASES
alias ls="eza --tree --level=1 --icons"
alias ls2="eza --tree --level=2 --icons"
alias ls3="eza --tree --level=3 --icons"
alias ls4="eza --tree --level=4 --icons"
alias lso="eza --oneline"
alias claude="npx @anthropic-ai/claude-code"
alias gg="lazygit"

# FUNCTIONS
# git worktree add helper -> always inside .worktree
function gwa
    set new_branch $argv[1]
    set base_branch $argv[2]

    # Set default base_branch if not provided
    if test -z "$base_branch"
        set base_branch origin/main
    end

    # ensure .worktree exists
    mkdir -p .worktree

    git worktree add ".worktree/$new_branch" -b "$new_branch" "$base_branch"
end

# git worktree checkout
function gwc
    set branch $argv[1]
    set worktree_path ".worktree/$branch"

    if not test -d "$worktree_path"
        echo "Error: Worktree branch '$branch' does not exist at $worktree_path"
        return 1
    end

    cd "$worktree_path"
end

# git worktree list
function gwl
    git worktree list
end

# git worktree remove
function gwr
    set branch $argv[1]
    set worktree_path ".worktree/$branch"

    if not test -d "$worktree_path"
        echo "Error: Worktree branch '$branch' does not exist at $worktree_path"
        return 1
    end

    git worktree remove "$worktree_path"
end

if status is-interactive
    # Commands to run in interactive sessions can go here
end


# Dont forget to refresh this config once you make edits
# Use this command to refresh: source ~/.config/fish/config.fish
