#!/usr/bin/env bash
set -u

SKILL_NAME="copilot-first-light"
SKILL_URL="https://raw.githubusercontent.com/DUBSOpenHub/copilot-first-light/main/.github/skills/copilot-first-light/SKILL.md"
ANIMATED_URL="https://raw.githubusercontent.com/DUBSOpenHub/copilot-first-light/main/quickstart.sh"
SKILL_DIR="$HOME/.copilot/skills/$SKILL_NAME"
WORK_DIR="${TMPDIR:-/tmp}/copilot-first-light.$$.$RANDOM"
ANIMATED_FILE="$WORK_DIR/quickstart.sh"
LOG_FILE="${TMPDIR:-/tmp}/copilot-first-light-install.$$.$RANDOM.log"
TTY_DEV=""
OS_NAME=""

if [ -r /dev/tty ] && [ -w /dev/tty ]; then
  TTY_DEV="/dev/tty"
fi

cleanup() {
  status=$?
  rm -rf "$WORK_DIR"
  if [ "$status" -eq 0 ]; then
    rm -f "$LOG_FILE"
  fi
}
trap cleanup EXIT INT TERM

if [ -t 1 ]; then
  RESET=$'\033[0m'
  BOLD=$'\033[1m'
  DIM=$'\033[2m'
  CYAN=$'\033[36m'
  MAGENTA=$'\033[35m'
  GREEN=$'\033[32m'
  YELLOW=$'\033[33m'
  RED=$'\033[31m'
else
  RESET=''
  BOLD=''
  DIM=''
  CYAN=''
  MAGENTA=''
  GREEN=''
  YELLOW=''
  RED=''
fi

print_line() {
  printf '%b%s%b\n' "$1" "$2" "$RESET"
}

print_box() {
  printf '%b┌──────────────────────────────────────────────┐%b\n' "$CYAN" "$RESET"
  printf '%b│%b ✨  Copilot First Light                     %b│%b\n' "$CYAN" "$RESET" "$CYAN" "$RESET"
  printf '%b│%b We will get everything ready for you.      %b│%b\n' "$CYAN" "$RESET" "$CYAN" "$RESET"
  printf '%b└──────────────────────────────────────────────┘%b\n' "$CYAN" "$RESET"
}

print_note_box() {
  printf '%b┌──────────────────────────────────────────────┐%b\n' "$MAGENTA" "$RESET"
  printf '%b│%b %s%b\n' "$MAGENTA" "$RESET" "$1" "$RESET"
  printf '%b└──────────────────────────────────────────────┘%b\n' "$MAGENTA" "$RESET"
}

spinner_frame() {
  case "$1" in
    0) printf '⠋' ;;
    1) printf '⠙' ;;
    2) printf '⠹' ;;
    3) printf '⠸' ;;
    4) printf '⠼' ;;
    5) printf '⠴' ;;
    6) printf '⠦' ;;
    7) printf '⠧' ;;
    8) printf '⠇' ;;
    *) printf '⠏' ;;
  esac
}

run_with_spinner() {
  step="$1"
  shift

  if [ -t 1 ]; then
    (
      "$@"
    ) >>"$LOG_FILE" 2>&1 &
    pid=$!
    i=0
    while kill -0 "$pid" 2>/dev/null; do
      frame=$(spinner_frame "$i")
      printf '\r  %b%s%b  %s' "$MAGENTA" "$frame" "$RESET" "$step"
      i=$(( (i + 1) % 10 ))
      sleep 0.1
    done
    wait "$pid"
    status=$?
    printf '\r\033[2K'
  else
    "$@" >>"$LOG_FILE" 2>&1
    status=$?
  fi

  if [ "$status" -eq 0 ]; then
    printf '  %b✅%b  %s\n' "$GREEN" "$RESET" "$step"
    return 0
  fi

  printf '  %b❌%b  %s\n' "$RED" "$RESET" "$step"
  return 1
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

ensure_brew_in_path() {
  if command_exists brew; then
    return 0
  fi

  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)" >/dev/null 2>&1
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)" >/dev/null 2>&1
  fi

  command_exists brew
}

install_homebrew() {
  ensure_brew_in_path && return 0
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/null
}

detect_os() {
  case "$(uname -s 2>/dev/null)" in
    Darwin)
      OS_NAME="macOS"
      ;;
    Linux)
      OS_NAME="Linux"
      ;;
    *)
      return 1
      ;;
  esac
}

install_gh_cli() {
  if command_exists gh; then
    return 0
  fi

  case "$OS_NAME" in
    macOS)
      ensure_brew_in_path || install_homebrew || return 1
      ensure_brew_in_path || return 1
      brew install gh </dev/null
      ;;
    Linux)
      # Use the official gh install script — no sudo prompts
      curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg 2>/dev/null | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
      if command_exists apt-get; then
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list 2>/dev/null
        apt-get update -y </dev/null 2>/dev/null && apt-get install -y gh </dev/null 2>/dev/null
      elif command_exists dnf; then
        dnf install -y gh </dev/null 2>/dev/null
      fi
      # Fallback: try the official install script
      if ! command_exists gh; then
        curl -fsSL https://cli.github.com/packages/install.sh 2>/dev/null | bash 2>/dev/null
      fi
      ;;
    *)
      return 1
      ;;
  esac

  command_exists gh
}

install_gh_copilot() {
  if gh copilot --help >/dev/null 2>&1; then
    return 0
  fi

  gh extension install github/gh-copilot
}

install_skill() {
  mkdir -p "$SKILL_DIR" && curl -fsSL "$SKILL_URL" -o "$SKILL_DIR/SKILL.md"
}

download_animated() {
  mkdir -p "$WORK_DIR" && curl -fsSL "$ANIMATED_URL" -o "$ANIMATED_FILE" && [ -s "$ANIMATED_FILE" ]
}

launch_animated() {
  if [ -n "$TTY_DEV" ]; then
    bash "$ANIMATED_FILE" <"$TTY_DEV"
  else
    bash "$ANIMATED_FILE"
  fi
}

handoff_to_gh() {
  if ! gh copilot --help >/dev/null 2>&1; then
    return 1
  fi

  printf '\n'
  print_note_box "You are all set. In the next screen, type ${BOLD}first light${RESET}"
  printf '\n'
  print_line "$DIM" "Opening GitHub Copilot..."
  sleep 1

  if [ -n "$TTY_DEV" ]; then
    exec <"$TTY_DEV"
  fi

  exec gh copilot
}

die() {
  printf '\n'
  print_note_box "$1"
  print_line "$DIM" "A quiet log was saved to: $LOG_FILE"
  exit 1
}

main() {
  clear 2>/dev/null || true
  printf '\n'
  print_box
  print_line "$DIM" "This keeps the setup gentle and out of the way."
  printf '\n'

  detect_os || die "This helper works on macOS and Linux."
  printf '  %b✅%b  %s\n' "$GREEN" "$RESET" "Computer check complete: $OS_NAME"

  if command_exists gh; then
    printf '  %b✅%b  %s\n' "$GREEN" "$RESET" "GitHub CLI is already here"
  else
    run_with_spinner "Installing GitHub CLI" install_gh_cli || die "I could not install GitHub CLI just yet."
  fi

  if gh copilot --help >/dev/null 2>&1; then
    printf '  %b✅%b  %s\n' "$GREEN" "$RESET" "GitHub Copilot is already connected"
  else
    run_with_spinner "Adding GitHub Copilot" install_gh_copilot || die "I could not add GitHub Copilot."
  fi

  run_with_spinner "Adding the First Light guide" install_skill || die "I could not add the First Light guide."
  run_with_spinner "Downloading the guided welcome" download_animated || die "I could not download the guided welcome."

  printf '\n'
  print_note_box "Next comes the friendly guided welcome. Sit back and follow along."
  printf '\n'

  if launch_animated; then
    handoff_to_gh || exit 0
  fi

  print_line "$YELLOW" "The guided welcome did not open, so I will take you straight to GitHub Copilot instead."
  handoff_to_gh || die "Everything is installed, but I could not open GitHub Copilot."
}

main "$@"
