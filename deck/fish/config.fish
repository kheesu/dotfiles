# ==============================================================================
#  config.fish — Steam Deck dev environment
#  Mirrors .bashrc with fish-native syntax.
# ==============================================================================

# Nix — fish-specific profile script (sets PATH, NIX_PATH, etc.)
if test -e $HOME/.nix-profile/etc/profile.d/nix.fish
    source $HOME/.nix-profile/etc/profile.d/nix.fish
end

# ------------------------------------------------------------------------------
# Environment
# ------------------------------------------------------------------------------
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx TERMINAL foot
set -gx BROWSER firefox

set -gx PATH $HOME/.local/bin $HOME/.cargo/bin $PATH

set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
set -gx MANROFFOPT "-c"

set -gx FZF_DEFAULT_COMMAND 'fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND

# ------------------------------------------------------------------------------
# Tool init
# ------------------------------------------------------------------------------
starship init fish | source
zoxide init fish --cmd cd | source   # overrides cd with zoxide (z / zi still work)
fzf --fish | source

# ------------------------------------------------------------------------------
# Aliases
# ------------------------------------------------------------------------------
alias ..    "cd .."
alias ...   "cd ../.."
alias ....  "cd ../../.."

alias ls    "eza --icons --group-directories-first"
alias ll    "eza -l --icons --group-directories-first --git"
alias la    "eza -la --icons --group-directories-first --git"
alias tree  "eza --tree --icons"
alias cat   bat
alias grep  rg
alias find  fd
alias top   btop

alias v     nvim
alias vim   nvim
alias g     git
alias gs    "git status"
alias ga    "git add"
alias gc    "git commit -m"
alias gp    "git push"
alias gl    "git log --oneline --graph --decorate --all"
alias py    python3

alias swayconf  "nvim ~/.config/sway/config"
alias nvimconf  "nvim ~/.config/nvim/init.lua"
alias fishconf  "nvim ~/.config/fish/config.fish"
alias reload    "source ~/.config/fish/config.fish"

alias install   "nix profile install nixpkgs#"
alias update    "nix profile upgrade '.*'"

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------
function ex --description "Extract any archive"
    if test -f $argv[1]
        switch $argv[1]
            case '*.tar.bz2';  tar xjf $argv[1]
            case '*.tar.gz';   tar xzf $argv[1]
            case '*.bz2';      bunzip2 $argv[1]
            case '*.gz';       gunzip  $argv[1]
            case '*.tar';      tar xf  $argv[1]
            case '*.tbz2';     tar xjf $argv[1]
            case '*.tgz';      tar xzf $argv[1]
            case '*.zip';      unzip   $argv[1]
            case '*.Z';        uncompress $argv[1]
            case '*.7z';       7z x    $argv[1]
            case '*';          echo "'$argv[1]' cannot be extracted via ex()"
        end
    else
        echo "'$argv[1]' is not a valid file"
    end
end

function mkcd --description "Make directory and cd into it"
    mkdir -p $argv[1] && cd $argv[1]
end

# ------------------------------------------------------------------------------
# Startup banner
# ------------------------------------------------------------------------------
if not set -q TMUX
    fastfetch
end
