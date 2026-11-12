# HOMEBREW
eval (/opt/homebrew/bin/brew shellenv)

fish_add_path /usr/local/bin
fish_add_path ~/.npm-global/bin
fish_add_path ~/bin

# XDG: lazygit reads ~/.config/lazygit on macOS
set -gx XDG_CONFIG_HOME "$HOME/.config"

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
alias gg="lazygit"
alias nd="neovide ."
alias nv="nvim ."
alias znv="cd ~/.config/nvim"

# GIT ALIASES
alias gst="git status"
alias gco="git checkout"
alias gcm="git commit -m"
alias gp="git push"
alias gl="git pull"
alias gd="git diff"
alias ga="git add"
alias gaa="git add --all"
alias gcb="git checkout -b"
alias glog="git log --oneline --graph --decorate"

# BAT INTEGRATION
if command -v bat &> /dev/null
    set -gx BAT_THEME "Catppuccin Mocha"
    alias cat="bat"
    set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
    set -gx MANROFFOPT "-c"
end

# DOCKER & KUBERNETES SHORTCUTS
alias d="docker"
alias dc="docker compose"
alias dps="docker ps"
alias dex="docker exec -it"
alias k="kubectl"
alias kgp="kubectl get pods"
alias kgs="kubectl get services"
alias kgd="kubectl get deployments"
alias kdp="kubectl describe pod"

# FUNCTIONS
# Internal: resolve the main worktree path (first entry in `git worktree list`)
function _gw_main_worktree
    git worktree list 2>/dev/null | head -1 | awk '{print $1}'
end

# Internal: resolve the base directory that holds all worktrees for this project
function _gw_worktree_base
    set main_worktree (_gw_main_worktree)
    set main_parent (dirname "$main_worktree")
    set project_name (basename "$main_worktree")
    echo "$main_parent/worktree/$project_name"
end

# Internal: resolve the standard worktree path for a given branch name
function _gw_worktree_path
    set branch $argv[1]
    echo (_gw_worktree_base)"/$branch"
end

# Internal: detect the repo's base branch (main/master/etc) via origin/HEAD
function _gw_base_branch
    git rev-parse --abbrev-ref origin/HEAD 2>/dev/null | string replace 'origin/' ''
end

# Internal: find the worktree path where a branch is currently checked out, if any
function _gw_find_branch_worktree
    set branch $argv[1]
    set cur_wt ""
    for line in (git worktree list --porcelain)
        switch $line
            case 'worktree *'
                set cur_wt (string sub -s 10 $line)
            case "branch refs/heads/$branch"
                echo $cur_wt
                return 0
        end
    end
end

# git worktree add helper -> creates worktree in parent directory structure
function gwa
    argparse 'n/name=' 'b/base=' -- $argv
    or return 1

    set new_branch $argv[1]
    set base_branch $argv[2]

    if test -z "$new_branch"
        set_color red
        echo "Error: Please specify a branch name"
        echo "Usage: gwa <branch> [base_branch] [-n|--name <worktree_name>] [-b|--base <base_branch>]"
        set_color normal
        return 1
    end

    # -b/--base overrides the positional base_branch, if both are given
    if set -q _flag_base
        set base_branch $_flag_base
    end

    # Worktree directory name defaults to the branch name; -n/--name overrides it
    set worktree_name $new_branch
    if set -q _flag_name
        set worktree_name $_flag_name
    end

    set worktree_path (_gw_worktree_path "$worktree_name")

    # If the branch already exists, just check it out into the new worktree
    # instead of trying to create it (git errors on `-b` for an existing branch).
    if git show-ref --verify --quiet "refs/heads/$new_branch"
        # A branch can only be checked out in one worktree at a time — detect that
        # and point at the existing worktree instead of surfacing git's raw error.
        set existing_path (_gw_find_branch_worktree $new_branch)

        if test -n "$existing_path"
            set_color red
            echo "Error: branch '$new_branch' is already checked out at $existing_path"
            echo "Run: cd \"$existing_path\"  (or: gwc $new_branch, if the worktree dir matches the branch name)"
            set_color normal
            return 1
        end

        if test -n "$base_branch"
            set_color yellow
            echo "Warning: branch '$new_branch' already exists; ignoring base branch '$base_branch'"
            set_color normal
        end

        mkdir -p (_gw_worktree_base)

        set_color cyan
        if test "$worktree_name" != "$new_branch"
            echo "Running: git worktree add \"$worktree_path\" \"$new_branch\" (worktree name: $worktree_name)"
        else
            echo "Running: git worktree add \"$worktree_path\" \"$new_branch\""
        end
        set_color normal

        git worktree add "$worktree_path" "$new_branch"
        return $status
    end

    # Auto-detect base branch if not provided
    if test -z "$base_branch"
        set base_branch (_gw_base_branch)

        if test -z "$base_branch"
            set_color red
            echo "Error: Base branch not found. You can run: gwa <new_branch> <base_branch>"
            set_color normal
            return 1
        end

        set base_branch "origin/$base_branch"
    end

    mkdir -p (_gw_worktree_base)

    set_color cyan
    if test "$worktree_name" != "$new_branch"
        echo "Running: git worktree add \"$worktree_path\" -b \"$new_branch\" \"$base_branch\" (worktree name: $worktree_name)"
    else
        echo "Running: git worktree add \"$worktree_path\" -b \"$new_branch\" \"$base_branch\""
    end
    set_color normal

    git worktree add "$worktree_path" -b "$new_branch" "$base_branch"
end

# git worktree switch-branch -> moves an existing branch into a (new or existing) worktree
function gws
    argparse 'n/name=' -- $argv
    or return 1

    set branch $argv[1]

    if test -z "$branch"
        set_color red
        echo "Error: Please specify a branch name"
        echo "Usage: gws <branch> [-n|--name <worktree_name>]"
        set_color normal
        return 1
    end

    if not git show-ref --verify --quiet "refs/heads/$branch"
        set_color red
        echo "Error: branch '$branch' does not exist"
        set_color normal
        return 1
    end

    # Worktree directory name defaults to the branch name; -n/--name overrides it
    set worktree_name $branch
    if set -q _flag_name
        set worktree_name $_flag_name
    end

    set target_path (_gw_worktree_path "$worktree_name")
    set main_worktree (_gw_main_worktree)
    set existing_path (_gw_find_branch_worktree $branch)

    # Target worktree dir already exists
    if test -d "$target_path"
        if test "$existing_path" = "$target_path"
            set_color cyan
            echo "Branch '$branch' is already in worktree: $target_path"
            set_color normal
            cd "$target_path"
            return 0
        end

        set_color red
        echo "Error: worktree '$worktree_name' already exists at $target_path but has a different branch checked out"
        echo "Run: gwr $worktree_name  (to remove it first), or choose a different -n name"
        set_color normal
        return 1
    end

    mkdir -p (_gw_worktree_base)

    # Branch is already checked out somewhere else -> relocate that worktree
    if test -n "$existing_path"
        if test "$existing_path" = "$main_worktree"
            set_color red
            echo "Error: branch '$branch' is checked out in the main worktree ($main_worktree)"
            echo "git can't move the main worktree. Switch it to another branch first: gwc <base_branch>"
            set_color normal
            return 1
        end

        set_color cyan
        echo "Running: git worktree move \"$existing_path\" \"$target_path\""
        set_color normal

        git worktree move "$existing_path" "$target_path"
        and cd "$target_path"
        return $status
    end

    # Not checked out anywhere yet -> just add it
    set_color cyan
    echo "Running: git worktree add \"$target_path\" \"$branch\""
    set_color normal

    git worktree add "$target_path" "$branch"
    and cd "$target_path"
end

# git worktree checkout
function gwc
    set branch $argv[1]

    if test -z "$branch"
        set_color red
        echo "Error: Please specify a branch name"
        echo "Usage: gwc <branch> | gwc main"
        set_color normal
        return 1
    end

    # Always resolve paths relative to the main worktree, works from anywhere
    set main_worktree (_gw_main_worktree)

    if test -z "$main_worktree"
        set_color red
        echo "Error: Not inside a git repository"
        set_color normal
        return 1
    end

    # Detect base branch name (main/master/etc)
    set base_branch (_gw_base_branch)

    # Switch to main worktree when targeting main/master/base branch
    if test "$branch" = "main" -o "$branch" = "master" -o "$branch" = "$base_branch"
        set_color cyan
        echo "Switching to main worktree: $main_worktree"
        set_color normal
        cd "$main_worktree"
        return 0
    end

    set worktree_path (_gw_worktree_path "$branch")

    if not test -d "$worktree_path"
        set_color red
        echo "Error: Worktree branch '$branch' does not exist at $worktree_path"
        set_color normal
        return 1
    end

    set_color cyan
    echo "Changing to worktree: $worktree_path"
    set_color normal

    cd "$worktree_path"
end

# git worktree list with enhanced formatting
function gwl
    set current_dir (pwd)
    set worktree_path ""
    set branch ""
    set commit ""
    set status_text ""
    set status_color ""

    for line in (git worktree list --porcelain)
        if string match -q "worktree *" $line
            # Print previous worktree info if exists
            if test -n "$worktree_path"
                echo -n "  "
                set_color yellow
                echo -n "Branch: $branch"
                set_color normal
                echo -n " | "
                set_color $status_color
                echo -n "Status: $status_text"
                set_color normal
                echo -n " | "
                set_color brblack
                echo "Commit: $commit"
                set_color normal
                echo ""
            end

            # Start new worktree
            set worktree_path (string replace "worktree " "" $line)

            # Check if this is the current worktree
            if test "$worktree_path" = "$current_dir"
                set_color green --bold
                echo -n "→ "
            else
                set_color normal
                echo -n "  "
            end

            set_color blue --bold
            echo -n (basename $worktree_path)
            set_color normal
            echo -n " "
            set_color brblack
            echo $worktree_path
            set_color normal

            # Check status for this worktree
            if test -d "$worktree_path"
                set -l git_status (git -C "$worktree_path" status --short 2>/dev/null)
                if test -n "$git_status"
                    set status_text "dirty (uncommitted changes)"
                    set status_color "red"
                else
                    set status_text "clean"
                    set status_color "green"
                end
            end
        else if string match -q "branch *" $line
            set branch (string replace "branch " "" $line | string replace "refs/heads/" "")
        else if string match -q "HEAD *" $line
            set commit (string replace "HEAD " "" $line | string sub -l 7)
        end
    end

    # Print last worktree info
    if test -n "$worktree_path"
        echo -n "  "
        set_color yellow
        echo -n "Branch: $branch"
        set_color normal
        echo -n " | "
        set_color $status_color
        echo -n "Status: $status_text"
        set_color normal
        echo -n " | "
        set_color brblack
        echo "Commit: $commit"
        set_color normal
        echo ""
    end
end

# git worktree fuzzy find and switch
function gwf
    # Get list of worktrees with their paths
    set worktrees (git worktree list | awk '{print $1}')

    if test (count $worktrees) -eq 0
        set_color red
        echo "Error: No worktrees found"
        set_color normal
        return 1
    end

    # Use fzf to select a worktree
    set selected (git worktree list | fzf --height 40% --reverse --border --prompt="Select worktree: " --preview 'git -C {1} log --oneline --graph --decorate -10 --color=always' --preview-window=right:50%)

    if test -n "$selected"
        set worktree_path (echo $selected | awk '{print $1}')
        set_color cyan
        echo "Switching to: $worktree_path"
        set_color normal
        cd "$worktree_path"
    end
end

# git worktree edit - open worktree in neovim
function gwe
    set branch $argv[1]

    if test -z "$branch"
        set_color red
        echo "Error: Please specify a branch name"
        echo "Usage: gwe <branch>"
        set_color normal
        return 1
    end

    set worktree_path (_gw_worktree_path "$branch")

    if not test -d "$worktree_path"
        set_color red
        echo "Error: Worktree branch '$branch' does not exist at $worktree_path"
        set_color normal
        return 1
    end

    set_color cyan
    echo "Opening worktree in neovim: $worktree_path"
    set_color normal

    nvim "$worktree_path"
end

# git worktree lazygit - open lazygit in worktree
function gwg
    set branch $argv[1]

    if test -z "$branch"
        set_color red
        echo "Error: Please specify a branch name"
        echo "Usage: gwg <branch>"
        set_color normal
        return 1
    end

    set worktree_path (_gw_worktree_path "$branch")

    if not test -d "$worktree_path"
        set_color red
        echo "Error: Worktree branch '$branch' does not exist at $worktree_path"
        set_color normal
        return 1
    end

    set_color cyan
    echo "Opening lazygit for worktree: $worktree_path"
    set_color normal

    lazygit -p "$worktree_path"
end

# git worktree remove with safety checks
function gwr
    set branch $argv[1]

    if test -z "$branch"
        set_color red
        echo "Error: Please specify a branch name"
        echo "Usage: gwr <branch>"
        set_color normal
        return 1
    end

    set worktree_path (_gw_worktree_path "$branch")

    if not test -d "$worktree_path"
        set_color red
        echo "Error: Worktree branch '$branch' does not exist at $worktree_path"
        set_color normal
        return 1
    end

    # Safety check: Check for uncommitted changes
    set git_status (git -C "$worktree_path" status --short 2>/dev/null)
    if test -n "$git_status"
        set_color red --bold
        echo "⚠ WARNING: Worktree has uncommitted changes!"
        set_color normal
        echo ""
        set_color yellow
        echo "Uncommitted changes:"
        set_color normal
        git -C "$worktree_path" status --short
        echo ""
        set_color yellow
        echo -n "Are you sure you want to remove this worktree? [y/N] "
        set_color normal
        read -l confirm

        if test "$confirm" != "y" -a "$confirm" != "Y"
            set_color cyan
            echo "Aborted. Worktree not removed."
            set_color normal
            return 0
        end
    end

    # Remove worktree
    set_color yellow
    echo "Removing worktree: $worktree_path"
    set_color normal
    git worktree remove "$worktree_path"

    # Delete branch
    set_color yellow
    echo "Deleting branch: $branch"
    set_color normal
    git branch -D "$branch"

    # Prune worktrees
    set_color yellow
    echo "Pruning worktrees..."
    set_color normal
    git worktree prune

    set_color green
    echo "Successfully removed worktree and deleted branch '$branch'"
    set_color normal
end

# git worktree cleanup - batch remove merged worktrees
function gwclean
    # Get the default base branch
    set base_branch (_gw_base_branch)
    if test -z "$base_branch"
        set_color red
        echo "Error: Could not determine base branch"
        set_color normal
        return 1
    end

    set_color yellow
    echo "Base branch: $base_branch"
    set_color normal
    echo ""

    set worktree_base (_gw_worktree_base)

    # Check if worktree directory exists
    if not test -d "$worktree_base"
        set_color yellow
        echo "No worktrees found at $worktree_base"
        set_color normal
        return 0
    end

    # Collect merged branches
    set merged_branches (git branch --merged $base_branch | string trim | grep -v "^\*" | grep -v "^$base_branch\$")
    set -l worktrees_to_clean

    for branch in $merged_branches
        set worktree_path "$worktree_base/$branch"
        if test -d "$worktree_path"
            set worktrees_to_clean $worktrees_to_clean "$branch"
        end
    end

    if test (count $worktrees_to_clean) -eq 0
        set_color green
        echo "No merged worktrees to clean up!"
        set_color normal
        return 0
    end

    set_color yellow
    echo "Found "(count $worktrees_to_clean)" merged worktree(s):"
    set_color normal
    for branch in $worktrees_to_clean
        echo "  - $branch"
    end
    echo ""

    # Use fzf for interactive selection
    set_color cyan
    echo "Select worktrees to remove (press TAB to select multiple, ENTER to confirm):"
    set_color normal
    set selected (printf "%s\n" $worktrees_to_clean | fzf --multi --height 50% --reverse --border --prompt="Select worktrees to remove: ")

    if test -z "$selected"
        set_color cyan
        echo "No worktrees selected. Cleanup cancelled."
        set_color normal
        return 0
    end

    echo ""
    set_color yellow
    echo "Removing selected worktrees..."
    set_color normal
    echo ""

    # Remove selected worktrees
    for branch in $selected
        set worktree_path "$worktree_base/$branch"

        set_color yellow
        echo "Processing: $branch"
        set_color normal

        # Remove worktree
        git worktree remove "$worktree_path" 2>/dev/null
        if test $status -eq 0
            # Delete branch
            git branch -D "$branch" 2>/dev/null
            set_color green
            echo "  ✓ Removed worktree and deleted branch: $branch"
            set_color normal
        else
            set_color red
            echo "  ✗ Failed to remove worktree: $branch"
            set_color normal
        end
    end

    echo ""
    # Prune worktrees
    set_color yellow
    echo "Pruning worktrees..."
    set_color normal
    git worktree prune

    set_color green
    echo "Cleanup complete!"
    set_color normal
end

set -g fish_greeting "Welcome, $USER"

if status is-interactive
    # Commands to run in interactive sessions can go here
end


# Dont forget to refresh this config once you make edits
# Use this command to refresh: source ~/.config/fish/config.fish


# BEGIN opam configuration
# This is useful if you're using opam as it adds:
#   - the correct directories to the PATH
#   - auto-completion for the opam binary
# This section can be safely removed at any time if needed.
test -r '/Users/prajwalchigod/.opam/opam-init/init.fish' && source '/Users/prajwalchigod/.opam/opam-init/init.fish' > /dev/null 2> /dev/null; or true
# END opam configuration
export PATH="$HOME/.local/bin:$PATH"
