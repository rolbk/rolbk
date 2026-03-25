#!/usr/bin/env bash
# Bootstrap script for Debian-based systems
set -euo pipefail

# ── Colors ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
step() { echo -e "\n${GREEN}▸ $1${NC}"; }
warn() { echo -e "${YELLOW}  ⚠ $1${NC}"; }

# ── System packages ────────────────────────────────────────────────────────
step "Installing apt packages"
sudo apt update
sudo apt install -y \
  build-essential git curl wget unzip file tree htop jq \
  zsh zsh-syntax-highlighting eza ripgrep \
  python3 python3-venv python3-pip \
  autojump thefuck

# ── Set zsh as default shell ───────────────────────────────────────────────
step "Setting zsh as default shell"
if [ "$SHELL" != "$(which zsh)" ]; then
  sudo chsh -s "$(which zsh)" $USER
  warn "Shell changed to zsh - will take effect on next login"
fi

# ── Write .zshrc (before Atuin install so the installer doesn't duplicate) ─
step "Writing ~/.zshrc"
cat >> "${HOME}/.zshrc" <<'ZSHRC'
# Enable Powerlevel10k instant prompt (keep near top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ── PATH ───────────────────────────────────────────────────────────────────
export PATH="$HOME/.atuin/bin:$HOME/.local/bin:$PATH"

# ── Powerlevel10k ──────────────────────────────────────────────────────────
source ~/.local/share/powerlevel10k/powerlevel10k.zsh-theme

# ── Aliases ────────────────────────────────────────────────────────────────
alias ls='eza'
alias l='ls -lah'
alias please='sudo'
alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias es='exec $SHELL'
alias f='fuck'
alias py='python'
alias pip='UV_PYTHON=~/.local/share/uv/global/bin/python uv pip'
alias venvc='python3 -m venv .venv; source .venv/bin/activate'
alias venva='source .venv/bin/activate'
alias serve='python3 -m http.server 80'

# ── Tools ──────────────────────────────────────────────────────────────────
eval "$(atuin init zsh)"
[ -f /usr/share/autojump/autojump.sh ] && . /usr/share/autojump/autojump.sh
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
eval $(thefuck --alias)

# ── p10k: lean base + overrides ───────────────────────────────────────────
source ~/.local/share/powerlevel10k/config/p10k-lean.zsh
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon dir vcs newline prompt_char)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
  status command_execution_time background_jobs direnv asdf virtualenv anaconda pyenv goenv
  nodenv nvm nodeenv rbenv rvm fvm luaenv jenv plenv perlbrew phpenv scalaenv haskell_stack
  kubecontext terraform aws aws_eb_env azure gcloud google_app_cred toolbox context nordvpn
  ranger yazi nnn lf xplr vim_shell midnight_commander nix_shell chezmoi_shell
  todo timewarrior taskwarrior per_directory_history time newline
)
typeset -g POWERLEVEL9K_VCS_BRANCH_ICON='\uF126 '
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_CHAR='·'
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_FOREGROUND=242
typeset -g POWERLEVEL9K_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=' '
typeset -g POWERLEVEL9K_RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL=' '
typeset -g POWERLEVEL9K_EMPTY_LINE_LEFT_PROMPT_FIRST_SEGMENT_END_SYMBOL='%{%}'
typeset -g POWERLEVEL9K_EMPTY_LINE_RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL='%{%}'
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX='%242F╭─'
typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_PREFIX='%242F├─'
typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX='%242F╰─'
typeset -g POWERLEVEL9K_LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL=' '
typeset -g POWERLEVEL9K_RULER_FOREGROUND=242
typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=always
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
unset POWERLEVEL9K_BATTERY_STAGES
typeset -g POWERLEVEL9K_BATTERY_STAGES='\uf58d\uf579\uf57a\uf57b\uf57c\uf57d\uf57e\uf57f\uf580\uf581\uf578'
(( ! $+functions[p10k] )) || p10k reload

# ── Options ────────────────────────────────────────────────────────────────
setopt HIST_IGNORE_SPACE
setopt AUTO_CD
setopt AUTO_LIST

ZSHRC

# ── Install Atuin ──────────────────────────────────────────────────────────
step "Installing Atuin"
if ! command -v atuin &>/dev/null; then
  curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh -s -- --non-interactive
  export PATH="$HOME/.atuin/bin:$PATH"
else
  warn "Atuin already installed"
fi
atuin import auto || warn "No shell history to import yet"

# ── Configure Atuin ────────────────────────────────────────────────────────
step "Configuring Atuin"
mkdir -p "${HOME}/.config/atuin"
cat > "${HOME}/.config/atuin/config.toml" <<'ATUIN'
search_mode = "fuzzy"
style = "compact"
inline_height = 25
show_preview = true
enter_accept = true
filter_mode = "global"
filter_mode_shell_up_key_binding = "host"
show_help = true
exit_mode = "return-original"
keymap_mode = "auto"
ATUIN

# ── Install Powerlevel10k ──────────────────────────────────────────────────
step "Installing Powerlevel10k"
P10K_DIR="${HOME}/.local/share/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
  warn "Already installed at $P10K_DIR"
fi

# ── Install uv ─────────────────────────────────────────────────────────────
step "Installing uv"
if ! command -v uv &>/dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
else
  warn "uv already installed"
fi
export PATH="$HOME/.local/bin:$PATH"

# ── Setup uv global Python + venv ──────────────────────────────────────────
step "Setting up uv Python + global venv"
uv python install 3.13
GLOBAL_VENV="$HOME/.local/share/uv/global"
if [ ! -d "$GLOBAL_VENV" ]; then
  uv venv "$GLOBAL_VENV"
fi
# Wrapper so bare `python` uses the global venv
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/python" <<'WRAPPER'
#!/bin/sh
exec ~/.local/share/uv/global/bin/python "$@"
WRAPPER
chmod +x "$HOME/.local/bin/python"

step "Done! Log out and back in (or run: exec zsh)"
