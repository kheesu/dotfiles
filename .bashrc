# ==============================================================================
#  HEAVY DUTY .BASHRC - ARCH LINUX DEV ENVIRONMENT
# ==============================================================================

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# ------------------------------------------------------------------------------
# 1. HISTORY CONTROL
# ------------------------------------------------------------------------------
# Huge history that appends instead of overwriting
HISTSIZE=50000
HISTFILESIZE=100000
shopt -s histappend
# Save multi-line commands as one entry
shopt -s cmdhist
# Don't save duplicates or commands starting with space
export HISTCONTROL=ignoreboth:erasedups

# ------------------------------------------------------------------------------
# 2. ENVIRONMENT VARIABLES
# ------------------------------------------------------------------------------
# Editor
export EDITOR="nvim"
export VISUAL="nvim"
export TERMINAL="kitty"
export BROWSER="microsoft-edge-stable"

# Path Expansion (Add Go, Cargo, Local bin)
export PATH="$HOME/.local/bin:$HOME/go/bin:$HOME/.cargo/bin:$PATH"

# Fcitx5 (Input Method)
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx

# Man Pages with Color (using bat as pager is cleaner, but less is standard)
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"

# FZF (Fuzzy Finder) Configuration
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --prompt='Find > ' \
--bind 'ctrl-/:toggle-preview' \
--preview 'bat --style=numbers --color=always --line-range :500 {}'"

# ------------------------------------------------------------------------------
# 3. MODERN TOOL INITIALIZATION
# ------------------------------------------------------------------------------
# Starship (The Prompt)
eval "$(starship init bash)"

# Zoxide (Smarter 'cd')
eval "$(zoxide init bash)"

# FZF (Keybindings: Ctrl+T=Files, Ctrl+R=History)
eval "$(fzf --bash)"

# ------------------------------------------------------------------------------
# 4. ALIASES (THE "RICE")
# ------------------------------------------------------------------------------
# Navigation
alias cd="z"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# Modern Replacements
alias ls="eza --icons --group-directories-first"
alias ll="eza -l --icons --group-directories-first --git"
alias la="eza -la --icons --group-directories-first --git"
alias tree="eza --tree --icons"
alias cat="bat"
alias grep="rg"
alias find="fd"
alias df="ncdu"  # Disk usage analyzer
alias top="btop" # Process viewer

# Developer Shortcuts
alias v="nvim"
alias vim="nvim"
alias g="git"
alias gs="git status"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias gl="git log --oneline --graph --decorate --all"
alias d="docker"
alias dc="docker-compose"
alias py="python"

# System
alias update="yay -Syu"
alias install="yay -S"
alias remove="yay -Rns"
alias unlock="sudo rm /var/lib/pacman/db.lck" # Fix pacman lock
alias mirrors="sudo reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist"
alias ip="ip -c" # Colorize IP output

# Config Editing (Fast access to your dotfiles)
alias conf="cd ~/.config"
alias bashconf="nvim ~/.bashrc"
alias hyprconf="nvim ~/.config/hypr/hyprland.conf"
alias nvimconf="nvim ~/.config/nvim/init.lua"
alias reload="source ~/.bashrc"

# ------------------------------------------------------------------------------
# 5. FUNCTIONS & UTILITIES
# ------------------------------------------------------------------------------

# Automatic extraction based on extension
ex() {
  if [ -f $1 ]; then
    case $1 in
    *.tar.bz2) tar xjf $1 ;;
    *.tar.gz) tar xzf $1 ;;
    *.bz2) bunzip2 $1 ;;
    *.rar) unrar x $1 ;;
    *.gz) gunzip $1 ;;
    *.tar) tar xf $1 ;;
    *.tbz2) tar xjf $1 ;;
    *.tgz) tar xzf $1 ;;
    *.zip) unzip $1 ;;
    *.Z) uncompress $1 ;;
    *.7z) 7z x $1 ;;
    *) echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Create a directory and cd into it
mkcd() {
  mkdir -p "$1"
  cd "$1"
}

# ------------------------------------------------------------------------------
# 6. STARTUP BANNER
# ------------------------------------------------------------------------------
# Only show if not inside Tmux to avoid clutter
if [ -z "$TMUX" ]; then
  fastfetch
fi
