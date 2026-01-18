# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# 1. History Settings
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend # Append to history, don't overwrite

# 2. Terminal Colors
alias grep='grep --color=auto'
alias ls='ls --color=auto'

# 3. Tool Initializations (The Magic)
# Initialize Starship Prompt
eval "$(starship init bash)"

# Initialize Zoxide (Smarter 'cd')
eval "$(zoxide init bash)"

# 4. Aliases
alias cd="z"               # Use zoxide for cd
alias ls="eza --icons"     # Modern ls
alias ll="eza -l --icons"  # List view
alias la="eza -la --icons" # List all
alias cat="bat"            # Modern cat
alias v="nvim"
alias vim="nvim"

# 5. Environment Variables
export EDITOR="nvim"
export VISUAL="nvim"

# Fcitx Setup (User Session)
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
