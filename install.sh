#!/usr/bin/env bash
set -euo pipefail

# free-code installer
# Usage: curl -fsSL https://raw.githubusercontent.com/master-dev0000/clawdcode-multi-llm/main/install.sh | bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

REPO="https://github.com/master-dev0000/clawdcode-multi-llm.git"
INSTALL_DIR="$HOME/clawdcode-multi-llm"
BUN_MIN_VERSION="1.3.11"

info()  { printf "${CYAN}[*]${RESET} %s\n" "$*"; }
ok()    { printf "${GREEN}[+]${RESET} %s\n" "$*"; }
warn()  { printf "${YELLOW}[!]${RESET} %s\n" "$*"; }
fail()  { printf "${RED}[x]${RESET} %s\n" "$*"; exit 1; }

header() {
  echo ""
  printf "${BOLD}${ORANGE}"
  cat << 'ART'
   █████████  ████                               ███   █████████                ███          
  ███▒▒▒▒▒███▒▒███                             ▒▒███  ███▒▒▒▒▒███             ▒▒███          
 ███     ▒▒▒  ▒███   ██████  █████ ███ █████ ███████ ███     ▒▒▒   ██████   ███████   ██████ 
▒███          ▒███  ▒▒▒▒▒███▒▒███ ▒███▒▒███ ███▒▒███▒███          ███▒▒███ ███▒▒███  ███▒▒███
▒███          ▒███   ███████ ▒███ ▒███ ▒███▒███ ▒███▒███         ▒███ ▒███▒███ ▒███ ▒███████ 
▒▒███     ███ ▒███  ███▒▒███ ▒▒███████████ ▒███ ▒███▒▒███     ███▒███ ▒███▒███ ▒███ ▒███▒▒▒  
 ▒▒█████████  █████▒▒████████ ▒▒████▒████  ▒▒████████▒▒█████████ ▒▒██████ ▒▒████████▒▒██████ 
  ▒▒▒▒▒▒▒▒▒  ▒▒▒▒▒  ▒▒▒▒▒▒▒▒   ▒▒▒▒ ▒▒▒▒    ▒▒▒▒▒▒▒▒  ▒▒▒▒▒▒▒▒▒   ▒▒▒▒▒▒   ▒▒▒▒▒▒▒▒  ▒▒▒▒▒▒  
 ██████   ██████          ████  █████    ███     █████      █████      ██████   ██████       
▒▒██████ ██████          ▒▒███ ▒▒███    ▒▒▒     ▒▒███      ▒▒███      ▒▒██████ ██████        
 ▒███▒█████▒███ █████ ████▒███ ███████  ████     ▒███       ▒███       ▒███▒█████▒███        
 ▒███▒▒███ ▒███▒▒███ ▒███ ▒███▒▒▒███▒  ▒▒███     ▒███       ▒███       ▒███▒▒███ ▒███        
 ▒███ ▒▒▒  ▒███ ▒███ ▒███ ▒███  ▒███    ▒███     ▒███       ▒███       ▒███ ▒▒▒  ▒███        
 ▒███      ▒███ ▒███ ▒███ ▒███  ▒███ ███▒███     ▒███      █▒███      █▒███      ▒███        
 █████     █████▒▒█████████████ ▒▒█████ █████    ███████████████████████████     █████       
▒▒▒▒▒     ▒▒▒▒▒  ▒▒▒▒▒▒▒▒▒▒▒▒▒   ▒▒▒▒▒ ▒▒▒▒▒    ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒     ▒▒▒▒▒

ART
  printf "${RESET}"
  printf "${DIM}  The integrated build of Claude Code Multi-LLM${RESET}\n"
  echo ""
}

# -------------------------------------------------------------------
# System checks
# -------------------------------------------------------------------

check_os() {
  case "$(uname -s)" in
    Darwin) OS="macos" ;;
    Linux)  OS="linux" ;;
    *)      fail "Unsupported OS: $(uname -s). macOS or Linux required." ;;
  esac
  ok "OS: $(uname -s) $(uname -m)"
}

check_git() {
  if ! command -v git &>/dev/null; then
    fail "git is not installed. Install it first:
    macOS:  xcode-select --install
    Linux:  sudo apt install git  (or your distro's equivalent)"
  fi
  ok "git: $(git --version | head -1)"
}

# Compare semver: returns 0 if $1 >= $2
version_gte() {
  [ "$(printf '%s\n' "$1" "$2" | sort -V | head -1)" = "$2" ]
}

check_bun() {
  if command -v bun &>/dev/null; then
    local ver
    ver="$(bun --version 2>/dev/null || echo "0.0.0")"
    if version_gte "$ver" "$BUN_MIN_VERSION"; then
      ok "bun: v${ver}"
      return
    fi
    warn "bun v${ver} found but v${BUN_MIN_VERSION}+ required. Upgrading..."
  else
    info "bun not found. Installing..."
  fi
  install_bun
}

install_bun() {
  curl -fsSL https://bun.sh/install | bash
  # Source the updated profile so bun is on PATH for this session
  export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
  export PATH="$BUN_INSTALL/bin:$PATH"
  if ! command -v bun &>/dev/null; then
    fail "bun installation succeeded but binary not found on PATH.
    Add this to your shell profile and restart:
      export PATH=\"\$HOME/.bun/bin:\$PATH\""
  fi
  ok "bun: v$(bun --version) (just installed)"
}

# -------------------------------------------------------------------
# Clone & build
# -------------------------------------------------------------------

clone_repo() {
  if [ -d "$INSTALL_DIR" ]; then
    warn "$INSTALL_DIR already exists"
    if [ -d "$INSTALL_DIR/.git" ]; then
      info "Pulling latest changes..."
      git -C "$INSTALL_DIR" pull --ff-only origin main 2>/dev/null || {
        warn "Pull failed, continuing with existing copy"
      }
    fi
  else
    info "Cloning repository..."
    git clone --depth 1 "$REPO" "$INSTALL_DIR"
  fi
  ok "Source: $INSTALL_DIR"
}

install_deps() {
  info "Installing dependencies..."
  cd "$INSTALL_DIR"
  bun install --frozen-lockfile 2>/dev/null || bun install
  ok "Dependencies installed"
}

build_binary() {
  info "Building clawdcode-multi-llm (all experimental features enabled)..."
  cd "$INSTALL_DIR"
  bun run build:dev:full
  ok "Binary built: $INSTALL_DIR/cli-dev"
}

link_binary() {
  local link_dir="$HOME/.local/bin"
  mkdir -p "$link_dir"

  ln -sf "$INSTALL_DIR/cli-dev" "$link_dir/free-code"
  ok "Symlinked: $link_dir/free-code"

  if ! echo "$PATH" | tr ':' '\n' | grep -qx "$link_dir"; then
    warn "$link_dir is not on your PATH"
    
    local profile_file="$HOME/.bashrc"
    if [ -n "${ZSH_VERSION:-}" ] || [ "$(basename "$SHELL")" = "zsh" ]; then
      profile_file="$HOME/.zshrc"
    fi
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$profile_file"
    ok "Automagicamente adicionado ao $profile_file. Recarregue a sessão depois!"
  fi
}

setup_custom_provider() {
  echo ""
  # Fallback gracefully if not attached to a TTY (like curl | bash script piping without /dev/tty)
  if [ ! -t 0 ]; then
    if [ -c /dev/tty ]; then
      
    else
      return 0
    fi
  else
    
  fi

  printf "${YELLOW}  [Opcional] Deseja habilitar e plugar um Provedor Customizado (OpenRouter, Groq, etc) agora de forma nativa no seu ambiente? [y/N]: ${RESET}"
  read -r setup_custom </dev/tty || setup_custom="n"
  
  if [[ "$setup_custom" =~ ^[Yy]$ ]]; then
    while true; do
      printf "${CYAN}  API Key do Provider (ex: sk-or-...): ${RESET}"
      read -r api_key </dev/tty
      
      printf "${CYAN}  Modelo Padrão (pressione Enter para google/gemini-3.1-pro): ${RESET}"
      read -r model </dev/tty
      model="${model:-google/gemini-3.1-pro}"

      printf "${CYAN}  Base URL (pressione Enter para https://openrouter.ai/api/v1): ${RESET}"
      read -r base_url </dev/tty
      base_url="${base_url:-https://openrouter.ai/api/v1}"
      
      info "Testando a conexão com $base_url usando o modelo $model..."
      
      # Try a simple lightweight request to test if API key and Model works
      local test_response
      local http_code
      test_response=$(curl -s -w "\n%{http_code}" -X POST "$base_url/chat/completions" \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json" \
        -d '{"model":"'"$model"'", "messages":[{"role":"user","content":"oi"}], "max_tokens":1}') || true
      
      http_code=$(echo "$test_response" | tail -n1)
      
      if [ "$http_code" = "200" ]; then
        ok "Conexão bem sucedida (HTTP 200)!"
        break
      else
        warn "Falha no teste! O servidor retornou HTTP $http_code."
        local erro=$(echo "$test_response" | sed '$d' | grep -o '"message": *"[^"]*"' | head -1 || true)
        if [ -n "$erro" ]; then printf "${RED}  Motivo: $erro${RESET}\n"; fi
        
        printf "${YELLOW}  Deseja tentar novamente? [Y/n]: ${RESET}"
        read -r retry_ans </dev/tty || retry_ans="y"
        if ! [[ "${retry_ans:-y}" =~ ^[Yy]$ ]]; then
          warn "Salvando assim mesmo..."
          break
        fi
      fi
    done
    
    profile_file="$HOME/.bashrc"
    if [ -n "${ZSH_VERSION:-}" ] || [ "$(basename "$SHELL")" = "zsh" ]; then
      profile_file="$HOME/.zshrc"
    fi

    echo "" >> "$profile_file"
    echo "# Custom Provider configuration for clawdcode-multi-llm" >> "$profile_file"
    echo "export CLAUDE_CODE_USE_CUSTOM_OPENAI=1" >> "$profile_file"
    echo "export CUSTOM_OPENAI_BASE_URL=\"$base_url\"" >> "$profile_file"
    echo "export CUSTOM_OPENAI_API_KEY=\"$api_key\"" >> "$profile_file"
    echo "export CUSTOM_OPENAI_MODEL=\"$model\"" >> "$profile_file"
    
    ok "Configurações injetadas no seu profile: $profile_file (recarregue seu terminal e aproveite)!"
  else
    info "Configuração pulada. Você pode setar as variáveis manualmente depois."
  fi
  
}

# -------------------------------------------------------------------
# Main
# -------------------------------------------------------------------

header
info "Starting installation..."
echo ""

check_os
check_git
check_bun
echo ""

clone_repo
install_deps
build_binary
link_binary
setup_custom_provider

echo ""
printf "${GREEN}${BOLD}  Installation complete!${RESET}\n"
echo ""
printf "  ${BOLD}Run it:${RESET}\n"
printf "    ${CYAN}free-code${RESET}                          # interactive REPL\n"
printf "    ${CYAN}free-code -p \"sua prompt\"${RESET}           # one-shot mode\n"
echo ""
printf "  ${BOLD}Configuração do Provider Fallback (Manual):${RESET}\n"
printf "    Para usar a provider customizada sem injetar automaticamente:\n"
printf "    ${CYAN}export CLAUDE_CODE_USE_CUSTOM_OPENAI=1${RESET}\n"
printf "    ${CYAN}export CUSTOM_OPENAI_API_KEY=\"sua-chave\"${RESET}\n"
printf "    ${CYAN}export CUSTOM_OPENAI_BASE_URL=\"https://openrouter.ai/api/v1\"${RESET}\n"
printf "    ${CYAN}export CUSTOM_OPENAI_MODEL=\"google/gemini-3.1-pro\"${RESET}\n"
echo ""
printf "  ${DIM}Source: $INSTALL_DIR${RESET}\n"
printf "  ${DIM}Binary: $INSTALL_DIR/cli-dev${RESET}\n"
printf "  ${DIM}Link:   ~/.local/bin/free-code${RESET}\n"
echo ""
