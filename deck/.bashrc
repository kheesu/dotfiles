# ==============================================================================
#  .BASHRC — Steam Deck dev environment
#  Mirrors the root project's .bashrc with deck-appropriate overrides.
# ==============================================================================

[[ $- != *i* ]] && return

# Source nix profile so all nix-installed tools are in PATH
[[ -f "${HOME}/.nix-profile/etc/profile.d/nix.sh" ]] && \
    . "${HOME}/.nix-profile/etc/profile.d/nix.sh"

# ------------------------------------------------------------------------------
# 1. HISTORY
# ------------------------------------------------------------------------------
HISTSIZE=50000
HISTFILESIZE=100000
shopt -s histappend
shopt -s cmdhist
export HISTCONTROL=ignoreboth:erasedups

# ------------------------------------------------------------------------------
# 2. ENVIRONMENT
# ------------------------------------------------------------------------------
export EDITOR="nvim"
export VISUAL="nvim"
export TERMINAL="foot"
export BROWSER="firefox"

export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"

export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"

export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="${FZF_DEFAULT_COMMAND}"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --prompt='Find > ' \
--bind 'ctrl-/:toggle-preview' \
--preview 'bat --style=numbers --color=always --line-range :500 {}'"

# ------------------------------------------------------------------------------
# 3. TOOL INIT
# ------------------------------------------------------------------------------
eval "$(starship init bash)"
eval "$(zoxide init bash)"
eval "$(fzf --bash)"

# ------------------------------------------------------------------------------
# 4. ALIASES
# ------------------------------------------------------------------------------
# Navigation
alias cd="z"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# Modern replacements
alias ls="eza --icons --group-directories-first"
alias ll="eza -l --icons --group-directories-first --git"
alias la="eza -la --icons --group-directories-first --git"
alias tree="eza --tree --icons"
alias cat="bat"
alias grep="rg"
alias find="fd"
alias top="btop"

# Developer shortcuts
alias v="nvim"
alias vim="nvim"
alias g="git"
alias gs="git status"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias gl="git log --oneline --graph --decorate --all"
alias py="python3"

# Config shortcuts (deck-specific)
alias swayconf="nvim ~/.config/sway/config"
alias nvimconf="nvim ~/.config/nvim/init.lua"
alias bashconf="nvim ~/.bashrc"
alias reload="source ~/.bashrc"

# Nix package management
alias install="nix profile install nixpkgs#"
alias update="nix profile upgrade '.*'"

# ------------------------------------------------------------------------------
# 5. FUNCTIONS
# ------------------------------------------------------------------------------
ex() {
    if [ -f "$1" ]; then
        case $1 in
        *.tar.bz2) tar xjf "$1" ;;
        *.tar.gz)  tar xzf "$1" ;;
        *.bz2)     bunzip2 "$1" ;;
        *.gz)      gunzip  "$1" ;;
        *.tar)     tar xf  "$1" ;;
        *.tbz2)    tar xjf "$1" ;;
        *.tgz)     tar xzf "$1" ;;
        *.zip)     unzip   "$1" ;;
        *.Z)       uncompress "$1" ;;
        *.7z)      7z x    "$1" ;;
        *) echo "'$1' cannot be extracted via ex()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

mkcd() { mkdir -p "$1" && cd "$1"; }

# ------------------------------------------------------------------------------
# 6. STARTUP BANNER
# ------------------------------------------------------------------------------
if [ -z "${TMUX}" ]; then
    fastfetch
fi
