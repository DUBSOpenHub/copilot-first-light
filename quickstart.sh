#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# First Light — Your First AI Agent
# ============================================================================
# Run with: curl -fsSL https://raw.githubusercontent.com/.../quickstart.sh | bash
#
# This script guides a complete beginner through building their first
# AI agent — no coding experience needed. It installs what's needed,
# asks a few questions, creates real files, and hands off to Copilot CLI.
# ============================================================================

# ---------------------------------------------------------------------------
# Pipe-safety: restore interactive stdin when run via curl|bash
# ---------------------------------------------------------------------------
if [ ! -t 0 ]; then
  exec < /dev/tty
fi

# ---------------------------------------------------------------------------
# ANSI Colors & Symbols
# ---------------------------------------------------------------------------
BOLD=$'\033[1m'
DIM=$'\033[2m'
ITALIC=$'\033[3m'
RESET=$'\033[0m'
CYAN=$'\033[36m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
MAGENTA=$'\033[35m'
BLUE=$'\033[34m'
WHITE=$'\033[97m'
RED=$'\033[31m'

# GitHub Copilot brand palette (256-color) — for cinematic intro
COPILOT_BLUE=$'\033[38;5;75m'       # #6CB6FF — Copilot sky blue
COPILOT_PURPLE=$'\033[38;5;141m'    # #B392F0 — Copilot purple
COPILOT_GREEN=$'\033[38;5;114m'     # #7EE787 — GitHub green / success
COPILOT_TEAL=$'\033[38;5;80m'       # #56D4DD — Copilot teal accent
COPILOT_LAVENDER=$'\033[38;5;183m'  # #D2A8FF — light lavender
COPILOT_MUTED=$'\033[38;5;245m'     # muted gray for subtle text
COPILOT_GOLD=$'\033[38;5;220m'      # warm gold for sparkles
COPILOT_PINK=$'\033[38;5;213m'      # soft pink accent
COPILOT_ORANGE=$'\033[38;5;208m'    # warm orange glow
COPILOT_CYAN_BRIGHT=$'\033[38;5;51m'  # bright cyan flash
COPILOT_WHITE_BRIGHT=$'\033[38;5;231m' # pure bright white

BOX_TL="╔" BOX_TR="╗" BOX_BL="╚" BOX_BR="╝"
BOX_H="═" BOX_V="║"
LINE_H="─"
CHECK="✓"

# ---------------------------------------------------------------------------
# State variables — filled in during the interactive flow
# ---------------------------------------------------------------------------
USER_NAME=""
AGENT_TYPE=""
AGENT_TYPE_INDEX=0
AGENT_NAME=""
PERSONALITY=""
PERSONALITY_INDEX=0
AGENT_DIR="$HOME/my-first-agent"
STATE_FILE="$HOME/.first-light-state"

# ---------------------------------------------------------------------------
# TUI Helpers — battle-tested bash 3.2+ compatible
# ---------------------------------------------------------------------------

term_width() {
  local w
  w=$(tput cols 2>/dev/null || echo 60)
  [[ $w -gt 80 ]] && w=80
  echo "$w"
}

# raw_term_width → stdout (actual terminal width, unclamped, for cinematic)
raw_term_width() {
  local w
  w="$(tput cols 2>/dev/null || echo 80)"
  printf '%s' "$w"
}

# raw_term_height → stdout (actual terminal height)
raw_term_height() {
  local h
  h="$(tput lines 2>/dev/null || echo 24)"
  printf '%s' "$h"
}

box() {
  local width
  width=$(( $(term_width) - 4 ))
  local inner=$(( width - 2 ))
  echo ""
  printf "  ${CYAN}${BOX_TL}"
  printf "%0.s${BOX_H}" $(seq 1 "$inner")
  printf "${BOX_TR}${RESET}\n"
  while IFS= read -r line || [[ -n "$line" ]]; do
    local stripped
    stripped=$(echo -e "$line" | sed 's/\x1b\[[0-9;]*m//g')
    local len=${#stripped}
    local pad=$(( inner - len - 2 ))
    [[ $pad -lt 0 ]] && pad=0
    printf "  ${CYAN}${BOX_V}${RESET} %b%*s ${CYAN}${BOX_V}${RESET}\n" "$line" "$pad" ""
  done
  printf "  ${CYAN}${BOX_BL}"
  printf "%0.s${BOX_H}" $(seq 1 "$inner")
  printf "${BOX_BR}${RESET}\n"
  echo ""
}

separator() {
  local width
  width=$(( $(term_width) - 4 ))
  printf "  ${DIM}"
  printf "%0.s${LINE_H}" $(seq 1 "$width")
  printf "${RESET}\n"
}

type_text() {
  local text="$1"
  local delay="${2:-0.03}"
  for (( i=0; i<${#text}; i++ )); do
    printf "%s" "${text:$i:1}"
    sleep "$delay"
  done
  echo ""
}

pause_gentle() {
  local msg="${1:-Press Enter to continue...}"
  echo ""
  printf "  ${DIM}${msg}${RESET}"
  read -r -s
  echo ""
}

MENU_RESULT=0
menu_select() {
  local options=("$@")
  local count=${#options[@]}
  local i=0
  while [ $i -lt $count ]; do
    printf "  ${GREEN}${BOLD}%d)${RESET}  %s\n" $(( i + 1 )) "${options[$i]}"
    i=$(( i + 1 ))
  done
  echo ""
  while true; do
    printf "  ${CYAN}Enter a number (1-${count}):${RESET} "
    read -r choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ]; then
      MENU_RESULT=$(( choice - 1 ))
      break
    fi
    printf "  ${DIM}Just type a number between 1 and ${count}.${RESET}\n"
  done
}

show_progress() {
  local msg="$1"
  local duration="${2:-2}"
  local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
  local end_time=$(( SECONDS + duration ))
  while [ $SECONDS -lt $end_time ]; do
    for frame in "${frames[@]}"; do
      printf "\r  ${CYAN}${frame}${RESET} ${msg}"
      sleep 0.1 2>/dev/null || sleep 1
    done
  done
  printf "\r  ${GREEN}${CHECK}${RESET} ${msg}\n"
}

to_lower() { echo "$1" | tr '[:upper:]' '[:lower:]'; }
to_upper_first() { echo "$(echo "${1:0:1}" | tr '[:lower:]' '[:upper:]')${1:1}"; }

# Randomized positive responses
random_name_reaction() {
  local reactions=(
    "I like it."
    "That's a great name."
    "Oh, fun name!"
    "Sounds perfect."
    "Nice pick."
    "Has a good ring to it."
  )
  local idx=$(( RANDOM % 6 ))
  echo "${reactions[$idx]}"
}

random_choice_reaction() {
  local reactions=(
    "Great choice!"
    "Solid pick."
    "Good one!"
    "Nice — love that."
    "Oh, that's a good one."
    "Perfect."
  )
  local idx=$(( RANDOM % 6 ))
  echo "${reactions[$idx]}"
}

random_greeting() {
  local name="$1"
  local greetings=(
    "Nice to meet you, ${name}. Let's build something together."
    "Hey ${name}! Let's make something cool."
    "${name} — great name. Let's get started."
    "Welcome, ${name}. This is going to be fun."
    "Good to meet you, ${name}. Ready to build?"
    "Alright ${name}, let's do this."
  )
  local idx=$(( RANDOM % 6 ))
  echo "${greetings[$idx]}"
}

cleanup() {
  tput cnorm 2>/dev/null || true
  echo ""
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# OS detection
# ---------------------------------------------------------------------------
detect_os() {
  local uname_out
  uname_out="$(uname -s 2>/dev/null || echo Unknown)"
  case "$uname_out" in
    Darwin*)  echo "mac" ;;
    Linux*)   echo "linux" ;;
    MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
    *)        echo "unknown" ;;
  esac
}

OS="$(detect_os)"

# ---------------------------------------------------------------------------
# Phase 0 — Silent Install
# ---------------------------------------------------------------------------
# Installs gh CLI, Copilot CLI extension, and the First Light skill.
# Shows beautiful progress spinners. Swallows errors gracefully.
# ---------------------------------------------------------------------------

install_phase() {
  clear
  echo ""
  echo ""
  printf "  ${CYAN}${BOLD}Setting things up for you...${RESET}\n"
  echo ""
  separator
  echo ""

  # --- Check / install gh CLI ---
  if command -v gh &>/dev/null; then
    show_progress "GitHub CLI found" 1
  else
    show_progress "Downloading GitHub CLI..." 2
    case "$OS" in
      mac)
        if command -v brew &>/dev/null; then
          brew install gh &>/dev/null 2>&1 || true
        fi
        ;;
      linux)
        if command -v apt-get &>/dev/null; then
          (sudo apt-get update -qq && sudo apt-get install -y -qq gh) &>/dev/null 2>&1 || true
        elif command -v dnf &>/dev/null; then
          sudo dnf install -y gh &>/dev/null 2>&1 || true
        fi
        ;;
    esac
    if command -v gh &>/dev/null; then
      show_progress "GitHub CLI installed" 1
    else
      show_progress "GitHub CLI — we'll set this up later" 1
    fi
  fi

  # --- Check / install Copilot CLI extension ---
  if gh copilot --version &>/dev/null 2>&1; then
    show_progress "The Copilot CLI is ready" 1
  else
    show_progress "Installing the Copilot CLI..." 2
    gh extension install github/gh-copilot &>/dev/null 2>&1 || true
    if gh copilot --version &>/dev/null 2>&1; then
      show_progress "The Copilot CLI is installed" 1
    else
      show_progress "The Copilot CLI — we'll finish this later" 1
    fi
  fi

  # --- Install First Light skill ---
  local skill_dir="$HOME/.copilot/skills/copilot-first-light"
  show_progress "Preparing your experience..." 2
  mkdir -p "$skill_dir" 2>/dev/null || true

  # Copy SKILL.md if running from the repo directory
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -f "$script_dir/.github/skills/copilot-first-light/SKILL.md" ]; then
    cp "$script_dir/.github/skills/copilot-first-light/SKILL.md" \
       "$skill_dir/SKILL.md" 2>/dev/null || true
  fi
  show_progress "Everything's ready" 1

  echo ""
  sleep 0.5
}

# ---------------------------------------------------------------------------
# Cinematic Intro — Pixar-level animated welcome sequence
# ---------------------------------------------------------------------------

intro_cinematic() {
  clear
  printf '\033[?25l'  # hide cursor

  local cw ch center_x center_y
  cw="$(raw_term_width)"
  ch="$(raw_term_height)"
  center_x=$(( cw / 2 ))
  center_y=$(( ch / 2 ))

  # ═══════════════════════════════════════════════════════════════════════════
  # ACT 1: DARKNESS → SINGLE STAR → CONSTELLATION
  # Like the first frame of a Pixar movie — total black, then... a twinkle.
  # ═══════════════════════════════════════════════════════════════════════════

  sleep 0.5

  # A single tiny star blinks on, center screen
  printf '\033[%d;%dH%s✦%s' "$center_y" "$center_x" "${COPILOT_GOLD}" "${RESET}"
  sleep 0.6
  # It pulses: dim → bright → dim
  printf '\033[%d;%dH%s✦%s' "$center_y" "$center_x" "${COPILOT_MUTED}" "${RESET}"
  sleep 0.15
  printf '\033[%d;%dH%s✦%s' "$center_y" "$center_x" "${COPILOT_WHITE_BRIGHT}" "${RESET}"
  sleep 0.15
  printf '\033[%d;%dH%s✧%s' "$center_y" "$center_x" "${COPILOT_GOLD}" "${RESET}"
  sleep 0.2

  # Stars appear around it — a constellation forming (inner ring)
  local star_chars="✦ ✧ ⋆ ˚ · ✦ ✧ ⋆"
  local s_arr
  s_arr=($star_chars)
  local angles=(-3 -2 -1 0 1 2 3)

  local ring
  for ring in 1 2 3; do
    local radius=$(( ring * 3 ))
    local si=0
    for offset in -3 -2 -1 0 1 2 3; do
      local sr=$(( center_y + offset * ring ))
      local sc=$(( center_x + (offset * radius / 2) ))
      # Keep within bounds
      [ "$sr" -lt 1 ] && sr=1
      [ "$sr" -gt "$ch" ] && sr="$ch"
      [ "$sc" -lt 1 ] && sc=1
      [ "$sc" -gt "$cw" ] && sc="$cw"
      local scolor
      case $(( (si + ring) % 5 )) in
        0) scolor="${COPILOT_BLUE}" ;;
        1) scolor="${COPILOT_PURPLE}" ;;
        2) scolor="${COPILOT_GOLD}" ;;
        3) scolor="${COPILOT_TEAL}" ;;
        4) scolor="${COPILOT_PINK}" ;;
      esac
      printf '\033[%d;%dH%s%s%s' "$sr" "$sc" "$scolor" "${s_arr[$(( si % 8 ))]}" "${RESET}"
      si=$(( si + 1 ))
    done
    sleep 0.25
  done
  sleep 0.3

  # Flash — everything brightens for a split second
  local flash_row
  for flash_row in $(( center_y - 1 )) "$center_y" $(( center_y + 1 )); do
    printf '\033[%d;%dH%s  ·  ✦  ⋆  ✧  ·  %s' "$flash_row" $(( center_x - 10 )) "${COPILOT_WHITE_BRIGHT}" "${RESET}"
  done
  sleep 0.15
  clear
  sleep 0.15

  # ═══════════════════════════════════════════════════════════════════════════
  # ACT 2: THE BIG BANG — particles explode outward from center
  # Like the lamp jumping in the Pixar intro — kinetic energy
  # ═══════════════════════════════════════════════════════════════════════════

  # Explosion ring 1 — close particles shoot out
  local exp_syms="✦ ✧ ⋆ · ˚ ✦ ✧ ⋆ ˚ · ✦ ✧ · ⋆ ✧ ✦"
  local e_arr
  e_arr=($exp_syms)
  local exp_colors
  exp_colors=("${COPILOT_GOLD}" "${COPILOT_ORANGE}" "${COPILOT_PINK}" "${COPILOT_PURPLE}" "${COPILOT_BLUE}" "${COPILOT_TEAL}" "${COPILOT_CYAN_BRIGHT}" "${COPILOT_LAVENDER}")

  local wave
  for wave in 1 2 3 4 5; do
    local spread=$(( wave * 3 ))
    local angle
    for angle in 0 1 2 3 4 5 6 7 8 9 10 11; do
      # Place particles in a rough circle using angle offsets
      local dy=0 dx=0
      case "$angle" in
        0)  dy=-1; dx=0  ;;
        1)  dy=-1; dx=1  ;;
        2)  dy=-1; dx=2  ;;
        3)  dy=0;  dx=2  ;;
        4)  dy=1;  dx=2  ;;
        5)  dy=1;  dx=1  ;;
        6)  dy=1;  dx=0  ;;
        7)  dy=1;  dx=-1 ;;
        8)  dy=1;  dx=-2 ;;
        9)  dy=0;  dx=-2 ;;
        10) dy=-1; dx=-2 ;;
        11) dy=-1; dx=-1 ;;
      esac
      local pr=$(( center_y + dy * spread ))
      local pc=$(( center_x + dx * spread ))
      [ "$pr" -lt 1 ] && continue
      [ "$pr" -gt "$ch" ] && continue
      [ "$pc" -lt 1 ] && continue
      [ "$pc" -gt "$cw" ] && continue
      local ec="${exp_colors[$(( angle % 8 ))]}"
      local es="${e_arr[$(( (angle + wave) % 16 ))]}"
      printf '\033[%d;%dH%s%s%s' "$pr" "$pc" "$ec" "$es" "${RESET}"
    done
    sleep 0.12
  done
  sleep 0.15

  # Quick fade — erase explosion particles (reverse order feels organic)
  for wave in 5 4 3 2 1; do
    local spread=$(( wave * 3 ))
    for angle in 0 1 2 3 4 5 6 7 8 9 10 11; do
      local dy=0 dx=0
      case "$angle" in
        0)  dy=-1; dx=0  ;;  1)  dy=-1; dx=1  ;;
        2)  dy=-1; dx=2  ;;  3)  dy=0;  dx=2  ;;
        4)  dy=1;  dx=2  ;;  5)  dy=1;  dx=1  ;;
        6)  dy=1;  dx=0  ;;  7)  dy=1;  dx=-1 ;;
        8)  dy=1;  dx=-2 ;;  9)  dy=0;  dx=-2 ;;
        10) dy=-1; dx=-2 ;;  11) dy=-1; dx=-1 ;;
      esac
      local pr=$(( center_y + dy * spread ))
      local pc=$(( center_x + dx * spread ))
      [ "$pr" -lt 1 ] && continue
      [ "$pr" -gt "$ch" ] && continue
      [ "$pc" -lt 1 ] && continue
      [ "$pc" -gt "$cw" ] && continue
      printf '\033[%d;%dH ' "$pr" "$pc"
    done
    sleep 0.03
  done
  sleep 0.2

  # ═══════════════════════════════════════════════════════════════════════════
  # ACT 3: BRANDED GITHUB COPILOT — logo + Mona mascot
  # Matches the official GitHub Copilot CLI banner
  # ═══════════════════════════════════════════════════════════════════════════

  clear

  # Big ASCII art letters (6 rows tall) — COPILOT block text
  local L0=" ██████╗  ██████╗ ██████╗ ██╗██╗      ██████╗ ████████╗"
  local L1="██╔════╝ ██╔═══██╗██╔══██╗██║██║     ██╔═══██╗╚══██╔══╝"
  local L2="██║      ██║   ██║██████╔╝██║██║     ██║   ██║   ██║   "
  local L3="██║      ██║   ██║██╔═══╝ ██║██║     ██║   ██║   ██║   "
  local L4="╚██████╗ ╚██████╔╝██║     ██║███████╗╚██████╔╝   ██║   "
  local L5=" ╚═════╝  ╚═════╝ ╚═╝     ╚═╝╚══════╝ ╚═════╝    ╚═╝   "

  # Mona pixel-art mascot (8 rows tall, 20 wide)
  local M0="       ▄█▄ ▄█▄      "
  local M1="    ┌──▀█▀─▀█▀──┐   "
  local M2="    │            │   "
  local M3="  ▐█│ ████  ████ │█▌"
  local M4="  ▐█│ ████  ████ │█▌"
  local M5="  ▐█│            │█▌"
  local M6="  ▐█│    ▐▌▐▌    │█▌"
  local M7="    └────────────┘   "

  local art_width=56
  local mona_width=20
  local mona_gap=2
  local total_width=$(( art_width + mona_gap + mona_width ))

  # If terminal too narrow for Mona, skip it
  local show_mona=true
  [ "$cw" -lt $(( total_width + 6 )) ] && show_mona=false

  local art_start
  if [ "$show_mona" = "true" ]; then
    art_start=$(( center_x - total_width / 2 ))
  else
    art_start=$(( center_x - art_width / 2 ))
  fi
  [ "$art_start" -lt 2 ] && art_start=2

  local title_top=$(( center_y - 5 ))
  [ "$title_top" -lt 3 ] && title_top=3

  # "Welcome to GitHub" header — appears first
  local header="Welcome to GitHub"
  local header_start=$(( art_start + 1 ))
  printf '\033[%d;%dH%s%s%s%s' $(( title_top - 2 )) "$header_start" "${DIM}" "${WHITE}" "$header" "${RESET}"
  sleep 0.3

  # Reveal COPILOT columns left-to-right — brand cyan color
  local lines_arr
  lines_arr=("$L0" "$L1" "$L2" "$L3" "$L4" "$L5")

  local col=0
  while [ "$col" -lt "$art_width" ]; do
    local tc="${COPILOT_TEAL}"

    local lr=0
    while [ "$lr" -lt 6 ]; do
      local line="${lines_arr[$lr]}"
      local char="${line:$col:1}"
      if [ -n "$char" ] && [ "$char" != " " ]; then
        printf '\033[%d;%dH%s%s%s%s' $(( title_top + lr )) $(( art_start + col )) "${BOLD}" "$tc" "$char" "${RESET}"
      fi
      lr=$(( lr + 1 ))
    done

    # Sparkle trail
    if [ $(( col % 2 )) -eq 0 ]; then
      local spark_r=$(( title_top + (col % 6) ))
      printf '\033[%d;%dH%s✦%s' "$spark_r" $(( art_start + col + 1 )) "${COPILOT_GOLD}" "${RESET}"
      [ "$col" -gt 2 ] && printf '\033[%d;%dH ' "$spark_r" $(( art_start + col - 1 ))
    fi

    if [ "$col" -lt 8 ] || [ "$col" -gt $(( art_width - 8 )) ]; then
      sleep 0.02
    else
      sleep 0.035
    fi
    col=$(( col + 1 ))
  done

  # Clean up trailing sparkles
  local lr=0
  while [ "$lr" -lt 6 ]; do
    printf '\033[%d;%dH ' $(( title_top + lr )) $(( art_start + art_width + 1 ))
    lr=$(( lr + 1 ))
  done
  sleep 0.2

  # Mona mascot "boots up" row by row (if terminal is wide enough)
  if [ "$show_mona" = "true" ]; then
    local mona_start=$(( art_start + art_width + mona_gap ))
    local mona_top=$(( title_top - 1 ))
    local mona_arr
    mona_arr=("$M0" "$M1" "$M2" "$M3" "$M4" "$M5" "$M6" "$M7")

    local mr=0
    while [ "$mr" -lt 8 ]; do
      local mline="${mona_arr[$mr]}"
      local mc=0
      local mlen=${#mline}
      while [ "$mc" -lt "$mlen" ]; do
        local mch="${mline:$mc:1}"
        if [ "$mch" != " " ]; then
          # Color the Mona parts
          local mcolor="${WHITE}"
          case "$mch" in
            ▄|▀|█)
              # Antennas and visor = cyan, side ears = pink
              if [ "$mr" -le 1 ]; then
                mcolor="${COPILOT_TEAL}"
              elif [ "$mr" -eq 3 ] || [ "$mr" -eq 4 ]; then
                if [ "$mc" -lt 4 ] || [ "$mc" -gt 16 ]; then
                  mcolor="${COPILOT_PINK}"
                else
                  mcolor="${COPILOT_TEAL}"
                fi
              elif [ "$mr" -eq 5 ] || [ "$mr" -eq 6 ]; then
                if [ "$mc" -lt 4 ] || [ "$mc" -gt 16 ]; then
                  mcolor="${COPILOT_PINK}"
                else
                  mcolor="${COPILOT_GREEN}"
                fi
              fi
              ;;
            ▐|▌)
              if [ "$mr" -ge 3 ] && [ "$mr" -le 6 ]; then
                if [ "$mc" -lt 4 ] || [ "$mc" -gt 16 ]; then
                  mcolor="${COPILOT_PINK}"
                else
                  mcolor="${COPILOT_GREEN}"
                fi
              fi
              ;;
            ┌|┐|└|┘|│|─|╶|╴)
              mcolor="${DIM}${WHITE}"
              ;;
          esac
          printf '\033[%d;%dH%s%s%s' $(( mona_top + mr )) $(( mona_start + mc )) "$mcolor" "$mch" "${RESET}"
        fi
        mc=$(( mc + 1 ))
      done
      sleep 0.15
      mr=$(( mr + 1 ))
    done
  fi
  sleep 0.3

  # "GitHub Copilot CLI" subtitle
  local sub="GitHub Copilot CLI"
  local sub_start=$(( art_start + (art_width / 2) - (${#sub} / 2) ))
  [ "$sub_start" -lt 2 ] && sub_start=2
  local sub_row=$(( title_top + 7 ))

  local si=0
  local slen=${#sub}
  while [ "$si" -lt "$slen" ]; do
    local sch="${sub:$si:1}"
    printf '\033[%d;%dH%s%s%s' "$sub_row" $(( sub_start + si )) "${COPILOT_MUTED}" "$sch" "${RESET}"
    si=$(( si + 1 ))
  done
  sleep 0.5

  # ═══════════════════════════════════════════════════════════════════════════
  # ACT 4: FLOATING SPARKLE FIELD — ambient particles drift upward
  # Like the lantern scene in Tangled — magical, alive
  # ═══════════════════════════════════════════════════════════════════════════

  local drift_syms="✦ ✧ ⋆ · ˚ ° ✦ ✧"
  local d_arr
  d_arr=($drift_syms)
  local drift_colors
  drift_colors=("${COPILOT_GOLD}" "${COPILOT_LAVENDER}" "${COPILOT_TEAL}" "${COPILOT_PINK}" "${COPILOT_BLUE}" "${COPILOT_PURPLE}" "${COPILOT_ORANGE}" "${COPILOT_CYAN_BRIGHT}")

  # Spawn 3 waves of rising particles (avoiding the title area)
  local dwave
  for dwave in 1 2 3; do
    local di=0
    while [ "$di" -lt 10 ]; do
      # Random-ish positions using arithmetic on di and dwave
      local dx=$(( (di * 7 + dwave * 13) % cw + 1 ))
      local dy=$(( ch - di * 2 + dwave ))
      [ "$dy" -lt 1 ] && dy=1
      [ "$dy" -gt "$ch" ] && dy="$ch"
      [ "$dx" -gt "$cw" ] && dx="$cw"
      local dc="${drift_colors[$(( (di + dwave) % 8 ))]}"
      local ds="${d_arr[$(( di % 8 ))]}"
      printf '\033[%d;%dH%s%s%s' "$dy" "$dx" "$dc" "$ds" "${RESET}"
      di=$(( di + 1 ))
    done
    sleep 0.1

    # Float them up one row (erase old, draw new)
    di=0
    while [ "$di" -lt 10 ]; do
      local dx=$(( (di * 7 + dwave * 13) % cw + 1 ))
      local dy=$(( ch - di * 2 + dwave ))
      [ "$dy" -lt 1 ] && { di=$(( di + 1 )); continue; }
      [ "$dy" -gt "$ch" ] && { di=$(( di + 1 )); continue; }
      [ "$dx" -gt "$cw" ] && { di=$(( di + 1 )); continue; }
      printf '\033[%d;%dH ' "$dy" "$dx"
      local ny=$(( dy - 1 ))
      [ "$ny" -ge 1 ] && {
        local dc="${drift_colors[$(( (di + dwave) % 8 ))]}"
        local ds="${d_arr[$(( di % 8 ))]}"
        printf '\033[%d;%dH%s%s%s' "$ny" "$dx" "$dc" "$ds" "${RESET}"
      }
      di=$(( di + 1 ))
    done
    sleep 0.15
  done
  sleep 0.2

  # ═══════════════════════════════════════════════════════════════════════════
  # ACT 5: PROGRESS BAR — cinematic loading with personality
  # ═══════════════════════════════════════════════════════════════════════════

  local bar_row=$(( title_top + 11 ))
  local bar_width=40
  local bar_start=$(( center_x - bar_width / 2 ))
  [ "$bar_start" -lt 2 ] && bar_start=2
  local label_arr
  label_arr=("Gathering stardust" "Warming up the AI" "Charging creative cores" "Almost there" "Preparing your experience")

  local i=0
  while [ $i -le $bar_width ]; do
    # Switch label at intervals
    local label_idx=0
    [ "$i" -ge $(( bar_width / 5 )) ] && label_idx=1
    [ "$i" -ge $(( bar_width * 2 / 5 )) ] && label_idx=2
    [ "$i" -ge $(( bar_width * 3 / 5 )) ] && label_idx=3
    [ "$i" -ge $(( bar_width * 4 / 5 )) ] && label_idx=4
    local current_label="${label_arr[$label_idx]}"

    # Draw bar with gradient fill
    printf '\033[%d;%dH%s[%s' "$bar_row" $(( bar_start - 1 )) "${COPILOT_BLUE}" "${RESET}"
    local j=0
    while [ $j -lt $bar_width ]; do
      if [ $j -lt $i ]; then
        local fill_color
        local fp=$(( j * 100 / bar_width ))
        if [ "$fp" -lt 20 ]; then
          fill_color="${COPILOT_BLUE}"
        elif [ "$fp" -lt 40 ]; then
          fill_color="${COPILOT_PURPLE}"
        elif [ "$fp" -lt 60 ]; then
          fill_color="${COPILOT_TEAL}"
        elif [ "$fp" -lt 80 ]; then
          fill_color="${COPILOT_GREEN}"
        else
          fill_color="${COPILOT_GOLD}"
        fi
        printf '%s█%s' "$fill_color" "${RESET}"
      else
        printf '%s░%s' "${COPILOT_MUTED}" "${RESET}"
      fi
      j=$(( j + 1 ))
    done
    local pct=$(( i * 100 / bar_width ))
    printf '%s]%s %s%3d%%%s' "${COPILOT_BLUE}" "${RESET}" "${COPILOT_LAVENDER}" "$pct" "${RESET}"

    # Label below bar
    printf '\033[%d;%dH%s%-35s%s' $(( bar_row + 1 )) "$bar_start" "${COPILOT_MUTED}" "$current_label" "${RESET}"

    # Sparkle next to the fill edge
    if [ "$i" -gt 0 ] && [ "$i" -lt "$bar_width" ]; then
      local spark_sym="✦"
      [ $(( i % 3 )) -eq 0 ] && spark_sym="✧"
      [ $(( i % 5 )) -eq 0 ] && spark_sym="⋆"
      printf '\033[%d;%dH%s%s%s' $(( bar_row - 1 )) $(( bar_start + i )) "${COPILOT_GOLD}" "$spark_sym" "${RESET}"
      # Erase previous sparkle
      [ "$i" -gt 1 ] && printf '\033[%d;%dH ' $(( bar_row - 1 )) $(( bar_start + i - 1 ))
    fi

    sleep 0.03
    i=$(( i + 1 ))
  done
  # Clean up last sparkle
  printf '\033[%d;%dH ' $(( bar_row - 1 )) $(( bar_start + bar_width ))
  sleep 0.3

  # ═══════════════════════════════════════════════════════════════════════════
  # ACT 6: THE BIG REVEAL — full screen transformation
  # Screen wipe, then the welcome message with animated steps
  # ═══════════════════════════════════════════════════════════════════════════

  # Screen wipe: horizontal gold line sweeps across
  local wipe_row=$(( center_y ))
  local wc=1
  while [ "$wc" -le "$cw" ]; do
    printf '\033[%d;%dH%s━%s' "$wipe_row" "$wc" "${COPILOT_GOLD}" "${RESET}"
    [ "$wc" -gt 1 ] && printf '\033[%d;%dH%s─%s' "$wipe_row" $(( wc - 1 )) "${COPILOT_MUTED}" "${RESET}"
    if [ $(( wc % 3 )) -eq 0 ]; then
      sleep 0.01
    fi
    wc=$(( wc + 1 ))
  done
  sleep 0.1

  # Wipe expands up and down simultaneously, clearing the screen
  local expand=1
  while [ "$expand" -lt $(( ch / 2 + 2 )) ]; do
    local up_row=$(( wipe_row - expand ))
    local dn_row=$(( wipe_row + expand ))
    [ "$up_row" -ge 1 ] && printf '\033[%d;1H\033[2K' "$up_row"
    [ "$dn_row" -le "$ch" ] && printf '\033[%d;1H\033[2K' "$dn_row"
    if [ $(( expand % 2 )) -eq 0 ]; then
      sleep 0.02
    fi
    expand=$(( expand + 1 ))
  done
  # Clear the wipe line itself
  printf '\033[%d;1H\033[2K' "$wipe_row"
  sleep 0.2

  # ── THE WELCOME SCREEN ──

  # Top sparkle border (full width)
  local accent_line=""
  i=0
  local aw=$(( cw - 4 ))
  [ "$aw" -gt 76 ] && aw=76
  while [ $i -lt "$aw" ]; do
    case $(( i % 8 )) in
      0) accent_line="${accent_line}✦" ;;
      1|7) accent_line="${accent_line} " ;;
      2) accent_line="${accent_line}·" ;;
      3) accent_line="${accent_line}✧" ;;
      4) accent_line="${accent_line}·" ;;
      5) accent_line="${accent_line}⋆" ;;
      6) accent_line="${accent_line}˚" ;;
    esac
    i=$(( i + 1 ))
  done

  local reveal_row=3
  printf '\033[%d;3H' "$reveal_row"
  # Sparkle border types in
  local al_len=${#accent_line}
  i=0
  while [ $i -lt $al_len ]; do
    printf '%s%s%s' "${COPILOT_PURPLE}" "${accent_line:$i:1}" "${RESET}"
    i=$(( i + 1 ))
  done
  printf '\n'
  sleep 0.15

  # WELCOME text — big and bold
  reveal_row=$(( reveal_row + 2 ))
  printf '\033[%d;3H' "$reveal_row"
  printf '  %s%s' "${BOLD}" "${COPILOT_BLUE}"
  type_text "  Welcome to the terminal." 0.05
  printf '%s' "${RESET}"
  sleep 0.3

  reveal_row=$(( reveal_row + 2 ))
  printf '\033[%d;3H' "$reveal_row"
  printf '  %s' "${WHITE}"
  type_text "  This is where you build your first AI agent with the GitHub Copilot CLI." 0.025
  printf '%s' "${RESET}"
  sleep 0.2

  reveal_row=$(( reveal_row + 1 ))
  printf '\033[%d;3H' "$reveal_row"
  printf '  %s' "${WHITE}"
  type_text "  Tell it what to do. Shape how it thinks." 0.025
  printf '%s' "${RESET}"
  sleep 0.2

  reveal_row=$(( reveal_row + 1 ))
  printf '\033[%d;3H' "$reveal_row"
  printf '  %s%s' "${BOLD}" "${COPILOT_PURPLE}"
  type_text "  You're about to build with the GitHub Copilot CLI." 0.04
  printf '%s' "${RESET}"
  sleep 0.4

  # The 4 steps — each one animates in with its emoji and a sparkle burst
  reveal_row=$(( reveal_row + 2 ))
  local s_arr
  s_arr=("🧠  Think it" "🔧  Shape it" "🤖  Build it" "🚀  Launch it")
  local s_colors
  s_colors=("${COPILOT_BLUE}" "${COPILOT_PURPLE}" "${COPILOT_TEAL}" "${COPILOT_GREEN}")
  local s_sparks
  s_sparks=("✦" "✧" "⋆" "✦")

  local si=0
  for step in "${s_arr[@]}"; do
    printf '\033[%d;5H' "$reveal_row"
    # Step fades in
    printf '%s  %s%s' "${s_colors[$si]}" "$step" "${RESET}"
    sleep 0.15
    # Checkmark pops in with a sparkle
    printf '  %s%s%s' "${COPILOT_GOLD}" "${s_sparks[$si]}" "${RESET}"
    sleep 0.15
    # Replace sparkle with green check
    printf '\b\b%s✓ %s' "${COPILOT_GREEN}" "${RESET}"
    printf '\n'
    reveal_row=$(( reveal_row + 1 ))
    si=$(( si + 1 ))
    sleep 0.2
  done

  # Bottom sparkle border
  reveal_row=$(( reveal_row + 1 ))
  printf '\033[%d;3H' "$reveal_row"
  printf '  %s%s%s' "${COPILOT_PURPLE}" "$accent_line" "${RESET}"
  printf '\n'
  sleep 0.4

  # Final ambient sparkles — scattered twinkles across the screen
  local twinkle
  for twinkle in 1 2 3 4 5; do
    local tx=$(( (twinkle * 17 + 3) % (cw - 2) + 1 ))
    local ty=$(( (twinkle * 5 + 1) % (ch - 2) + 1 ))
    # Don't overwrite the content area
    if [ "$ty" -lt 3 ] || [ "$ty" -gt $(( reveal_row + 1 )) ]; then
      local tc
      case $(( twinkle % 4 )) in
        0) tc="${COPILOT_GOLD}" ;;
        1) tc="${COPILOT_LAVENDER}" ;;
        2) tc="${COPILOT_TEAL}" ;;
        3) tc="${COPILOT_PINK}" ;;
      esac
      printf '\033[%d;%dH%s✦%s' "$ty" "$tx" "$tc" "${RESET}"
      sleep 0.1
    fi
  done
  sleep 0.5

  # Position cursor below content for next phase
  printf '\033[%d;1H' $(( reveal_row + 3 ))
  printf '\033[?25h'  # restore cursor
}


# ---------------------------------------------------------------------------
# Phase 1 — Welcome
# ---------------------------------------------------------------------------

welcome_phase() {
  if [ "${COPILOT_FIRST_LIGHT_BOOTSTRAP:-}" != "1" ]; then
    # Standalone — run the full cinematic
    intro_cinematic
  fi

  # Continue the scroll — no clear
  echo ""
  echo ""
  printf "  What's your first name?\n\n"
  printf "  ${GREEN}>${RESET} "
  read -r USER_NAME

  if [ -z "$USER_NAME" ]; then
    USER_NAME="friend"
  fi

  USER_NAME="$(to_upper_first "$USER_NAME")"

  echo ""
  printf "  "
  type_text "$(random_greeting "${USER_NAME}")" 0.03
  echo ""
  pause_gentle "Press Enter when you're ready..."
}

# ---------------------------------------------------------------------------
# Phase 2 — Pick Your Agent
# ---------------------------------------------------------------------------

pick_agent_phase() {
  clear
  echo ""
  echo ""
  printf "  ${BOLD}${WHITE}What should your agent do?${RESET}\n"
  echo ""
  printf "  "
  type_text "Pick the one that sounds most useful to you." 0.03
  echo ""
  printf "  ${DIM}(Just type a number)${RESET}\n"
  echo ""

  menu_select \
    "📧  Help me write better emails" \
    "📋  Summarize long documents" \
    "💡  Brainstorm ideas with me" \
    "🎨  Something else entirely"

  AGENT_TYPE_INDEX=$MENU_RESULT

  case $AGENT_TYPE_INDEX in
    0) AGENT_TYPE="email" ;;
    1) AGENT_TYPE="summarize" ;;
    2) AGENT_TYPE="brainstorm" ;;
    3) AGENT_TYPE="custom" ;;
  esac

  local choice_labels=("writing better emails" "summarizing documents" "brainstorming ideas" "something custom")
  local chosen="${choice_labels[$AGENT_TYPE_INDEX]}"

  echo ""
  printf "  ${GREEN}${CHECK}${RESET} $(random_choice_reaction) ${BOLD}${chosen}${RESET}.\n"
  echo ""
  sleep 0.8
}

# ---------------------------------------------------------------------------
# Phase 3 — Name Your Agent
# ---------------------------------------------------------------------------

name_agent_phase() {
  clear
  echo ""
  echo ""
  printf "  ${BOLD}${WHITE}Every agent needs a name.${RESET}\n"
  echo ""
  printf "  "
  type_text "It can be anything. Serious, silly, whatever feels right." 0.03
  echo ""

  local suggestions
  case $AGENT_TYPE in
    email)      suggestions="(Some people like: Echo, Scout, Penpal, Dash)" ;;
    summarize)  suggestions="(Some people like: Spark, Digest, Brief, Nutshell)" ;;
    brainstorm) suggestions="(Some people like: Muse, Bounce, Riff, Spark)" ;;
    custom)     suggestions="(Some people like: Sidekick, Kit, Helper, Buddy)" ;;
  esac

  printf "  ${DIM}${suggestions}${RESET}\n"
  echo ""
  printf "  ${BOLD}What should yours be called?${RESET}\n"
  echo ""
  printf "  ${CYAN}> ${RESET}"
  read -r AGENT_NAME

  if [ -z "$AGENT_NAME" ]; then
    AGENT_NAME="Buddy"
  fi

  AGENT_NAME="$(to_upper_first "$AGENT_NAME")"

  echo ""
  printf "  "
  type_text "${AGENT_NAME}. $(random_name_reaction)" 0.04
  echo ""
  sleep 0.6
}

# ---------------------------------------------------------------------------
# Phase 4 — Pick a Personality
# ---------------------------------------------------------------------------

pick_personality_phase() {
  clear
  echo ""
  echo ""
  printf "  ${BOLD}${WHITE}How should ${AGENT_NAME} talk?${RESET}\n"
  echo ""
  printf "  "
  type_text "This sets the tone for everything it writes." 0.03
  echo ""
  printf "  ${DIM}(Just type a number)${RESET}\n"
  echo ""

  menu_select \
    "🎯  Professional & direct" \
    "😊  Warm & encouraging" \
    "🧠  Thoughtful & detailed" \
    "⚡  Quick & punchy"

  PERSONALITY_INDEX=$MENU_RESULT

  local personality_names=("professional" "warm" "thoughtful" "punchy")
  local personality_labels=(
    "professional and direct"
    "warm and encouraging"
    "thoughtful and detailed"
    "quick and punchy"
  )
  PERSONALITY="${personality_names[$PERSONALITY_INDEX]}"

  echo ""
  printf "  ${GREEN}${CHECK}${RESET} ${AGENT_NAME} will be ${BOLD}${personality_labels[$PERSONALITY_INDEX]}${RESET}.\n"
  echo ""
  sleep 0.8
}

# ---------------------------------------------------------------------------
# Phase 5 — Animated Build
# ---------------------------------------------------------------------------

build_phase() {
  clear
  echo ""
  echo ""
  printf "  ${BOLD}${WHITE}Building ${AGENT_NAME}...${RESET}\n"
  echo ""
  separator
  echo ""

  # Create the agent directory
  mkdir -p "$AGENT_DIR" 2>/dev/null || true

  # Compose the system prompt based on agent type
  local type_instruction=""
  case $AGENT_TYPE in
    email)
      type_instruction="You help people write clear, effective emails. When given a topic or draft, you rewrite or compose an email that communicates the message well."
      ;;
    summarize)
      type_instruction="You help people understand long documents quickly. When given text, you create clear, accurate summaries that capture the key points."
      ;;
    brainstorm)
      type_instruction="You help people think through ideas. When given a topic, you offer creative angles, ask good questions, and help develop rough thoughts into clear concepts."
      ;;
    custom)
      type_instruction="You're a flexible AI agent. You adapt to whatever task the user needs, always being clear and useful."
      ;;
  esac

  # Compose the personality instruction
  local personality_instruction=""
  case $PERSONALITY in
    professional)
      personality_instruction="Be direct, clear, and polished. No fluff. Get to the point."
      ;;
    warm)
      personality_instruction="Be friendly, supportive, and encouraging. Use a conversational tone."
      ;;
    thoughtful)
      personality_instruction="Be thorough and nuanced. Consider multiple angles. Explain your reasoning."
      ;;
    punchy)
      personality_instruction="Be brief and energetic. Short sentences. No filler."
      ;;
  esac

  show_progress "Creating a folder for ${AGENT_NAME}" 2

  # Write the agent prompt file
  cat > "$AGENT_DIR/prompt.md" << AGENT_EOF
# ${AGENT_NAME}

${type_instruction}

## Personality
${personality_instruction}

## Rules
- Always be helpful and clear
- If you're not sure what the user wants, ask
- Keep your responses focused and useful
- Use plain language — no jargon
AGENT_EOF

  show_progress "Writing ${AGENT_NAME}'s personality" 2

  # Write a sample input file based on agent type
  local sample_input=""
  case $AGENT_TYPE in
    email)
      sample_input="Subject: Following up on our meeting\n\nHey — just wanted to follow up on what we talked about yesterday. I think the timeline works but I have a couple questions about the budget. Can we chat Thursday?"
      ;;
    summarize)
      sample_input="Paste any long text here and ${AGENT_NAME} will summarize it for you.\n\nTry it with an article, a long email chain, meeting notes, or any document that needs a quick summary."
      ;;
    brainstorm)
      sample_input="Topic: Planning a team offsite\n\nWe need ideas for a two-day team offsite for 15 people. Budget is moderate. Goal is team bonding plus strategic planning. The team is mostly remote."
      ;;
    custom)
      sample_input="Write anything here and ${AGENT_NAME} will help.\n\nYou can ask it to write, edit, summarize, brainstorm, explain, or anything else you need."
      ;;
  esac

  printf "%b" "$sample_input" > "$AGENT_DIR/sample-input.txt"
  show_progress "Adding a sample for you to try" 1

  # Save state for the Copilot CLI skill to read later
  cat > "$STATE_FILE" << STATE_EOF
USER_NAME="${USER_NAME}"
AGENT_NAME="${AGENT_NAME}"
AGENT_TYPE="${AGENT_TYPE}"
PERSONALITY="${PERSONALITY}"
AGENT_DIR="${AGENT_DIR}"
CREATED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
STATE_EOF

  show_progress "Saving your choices" 1

  echo ""
  separator
  echo ""
  sleep 0.5

  # --- The teaching moment ---
  printf "  ${BOLD}${WHITE}Done!${RESET}\n"
  echo ""
  sleep 0.5
  printf "  "
  type_text "So." 0.04
  sleep 0.8
  type_text "Those files that just appeared on your computer?" 0.03
  sleep 0.6
  type_text "That's not a demo. That actually happened." 0.03
  sleep 1.0
  echo ""
  type_text "${AGENT_NAME} exists now — on this machine, in a real folder you can open." 0.03
  sleep 0.8
  type_text "You didn't install an app. You ${BOLD}built${RESET} something." 0.03
  sleep 0.6
  type_text "A prompt file, a config, a structure — the same pieces a developer would create." 0.03
  sleep 0.8
  type_text "All powered by the ${CYAN}GitHub Copilot CLI${RESET}." 0.03
  sleep 1.4
  type_text "${DIM}You just didn't need to be a developer to do it.${RESET}" 0.03
  sleep 1.0
  echo ""

  pause_gentle "Press Enter to see what you built..."
}

# ---------------------------------------------------------------------------
# Phase 5b — Show What Was Created
# ---------------------------------------------------------------------------

show_creation_phase() {
  clear
  echo ""
  echo ""

  printf "  ${BOLD}${WHITE}Here's what's inside your folder:${RESET}\n"
  echo ""
  printf "  ${CYAN}~/my-first-agent/${RESET}\n"
  printf "  ${DIM}├── ${RESET}prompt.md       ${DIM}← ${AGENT_NAME}'s personality & instructions${RESET}\n"
  printf "  ${DIM}└── ${RESET}sample-input.txt ${DIM}← Something to try it on${RESET}\n"
  echo ""
  separator
  echo ""
  sleep 0.5

  printf "  Let me show you what ${BOLD}prompt.md${RESET} looks like:\n"
  echo ""

  # Display the prompt file with a left-border style
  while IFS= read -r line || [[ -n "$line" ]]; do
    printf "  ${DIM}│${RESET} %s\n" "$line"
  done < "$AGENT_DIR/prompt.md"

  echo ""
  sleep 0.5
  printf "  "
  type_text "Here's what I want you to sit with for a second." 0.03
  sleep 1.2
  type_text "Five minutes ago, you'd never opened a terminal." 0.03
  sleep 0.8
  type_text "Now you have an AI agent called ${BOLD}${AGENT_NAME}${RESET} that follows instructions you wrote." 0.03
  sleep 1.4
  echo ""
  type_text "Not instructions someone gave you." 0.03
  sleep 0.5
  type_text "${BOLD}Your${RESET} words. ${BOLD}Your${RESET} rules. ${BOLD}Your${RESET} agent." 0.03
  sleep 1.6
  echo ""
  type_text "That feeling right now — that little ${CYAN}wait, really?${RESET} — remember it." 0.03
  sleep 0.8
  type_text "That's what building feels like." 0.03
  sleep 0.8
  type_text "And this is just the beginning of what the ${CYAN}Copilot CLI${RESET} can do." 0.03
  sleep 1.2
  echo ""

  pause_gentle "Press Enter to continue..."
}

# ---------------------------------------------------------------------------
# Phase 6 — Mock Demo
# ---------------------------------------------------------------------------

demo_phase() {
  clear
  echo ""
  echo ""

  printf "  ${BOLD}${WHITE}Let's see ${AGENT_NAME} in action.${RESET}\n"
  echo ""
  sleep 0.5
  printf "  "
  type_text "Here's what it would do with your sample input:" 0.03
  echo ""
  separator
  echo ""

  # Build a mock response based on type + personality
  local mock_response=""
  case "${AGENT_TYPE}-${PERSONALITY}" in
    email-professional)
      mock_response="Subject: Meeting Follow-Up — Budget Questions

Hi [Name],

Thanks for the productive meeting yesterday. The proposed timeline looks solid.

I have two questions about the budget:
1. Is the Q2 allocation finalized?
2. Do we have flexibility on the vendor line items?

Could we connect Thursday afternoon? I'm open after 2 PM.

Best,
[Your name]"
      ;;
    email-warm)
      mock_response="Subject: Great chat yesterday! Quick follow-up

Hey [Name]!

Really enjoyed our conversation yesterday — lots of good stuff.

The timeline sounds great to me! I do have a couple of thoughts on
the budget side I'd love to run by you. Nothing major, just want
to make sure we're on the same page.

Any chance you're free Thursday for a quick chat?

Talk soon!"
      ;;
    email-thoughtful)
      mock_response="Subject: Follow-Up: Meeting Discussion & Budget Considerations

Hi [Name],

Thank you for yesterday's meeting. I've been reflecting on our
discussion and wanted to share my thoughts.

Regarding the timeline: I think the proposed schedule is workable.
However, I want to flag two budget-related considerations:

1. The current allocation assumes steady resource availability.
2. We may want a contingency buffer for vendor costs.

Would Thursday work for a 30-minute call to discuss?

Best regards"
      ;;
    email-punchy)
      mock_response="Subject: Quick follow-up

Hey —

Timeline works. Two budget questions:
• Is Q2 locked in?
• Any flex on vendor costs?

Thursday work for a call?

— [You]"
      ;;
    summarize-*)
      mock_response="Quick summary of your document:

• Main point: The proposed timeline is agreed upon
• Open question: Budget details need clarification
• Action item: Schedule follow-up for Thursday
• Key concern: Two specific budget items need discussion

Bottom line: Good progress, just need to nail down the numbers."
      ;;
    brainstorm-*)
      mock_response="Here are some ideas for your team offsite:

Day 1 — Bonding
• Morning: Cooking class together (works for all levels)
• Afternoon: Life map exercise — everyone shares their journey
• Evening: Casual dinner, no agenda

Day 2 — Strategy
• Morning: What's broken? Sticky note session (honest, anonymous)
• Afternoon: Pick top 3 problems, small groups draft solutions
• Close: Each group presents a 5-minute pitch

Wild card ideas:
• Start with a remote work show and tell
• End with handwritten notes to each team member"
      ;;
    custom-*)
      mock_response="I'm ready to help! Here's what I can do:

• Write or rewrite anything — emails, messages, documents
• Summarize long text into key points
• Help you think through ideas and problems
• Explain complex topics in plain language

Just paste some text or tell me what you need.

Tip: The more context you give me, the better I can help."
      ;;
  esac

  printf "  ${DIM}┌─ ${AGENT_NAME}'s response ─────────────────────────┐${RESET}\n"
  echo ""

  # Type out the mock response line by line
  while IFS= read -r line || [[ -n "$line" ]]; do
    printf "  "
    type_text "  $line" 0.015
    sleep 0.1
  done <<< "$mock_response"

  echo ""
  printf "  ${DIM}└──────────────────────────────────────────────┘${RESET}\n"
  echo ""
  sleep 0.5

  printf "  "
  type_text "Pretty cool, right?" 0.04
  echo ""
  sleep 0.3
  printf "  "
  type_text "That's ${AGENT_NAME} doing its thing." 0.03
  echo ""
  printf "  "
  type_text "And you can change how it works just by editing that text file." 0.03
  echo ""

  pause_gentle "Press Enter to continue..."
}

# ---------------------------------------------------------------------------
# Phase 7 — The Bridge (GitHub account guidance)
# ---------------------------------------------------------------------------

bridge_phase() {
  clear
  echo ""
  echo ""

  sleep 0.8
  type_text "Right now, ${AGENT_NAME} lives on this computer." 0.03
  sleep 0.6
  type_text "Which is fine — it works. But it's a little like writing a song and never saving the file." 0.03
  sleep 1.0
  echo ""
  type_text "GitHub is where people keep the things they build." 0.03
  sleep 0.5
  type_text "Developers use it. And now AI-native builders like yourself can too — and it's free." 0.03
  sleep 1.0
  echo ""
  type_text "If you grab a free GitHub account, you can:" 0.03
  sleep 0.4
  type_text "  ${GREEN}${CHECK}${RESET} Save ${AGENT_NAME} so it's yours permanently" 0.03
  sleep 0.3
  type_text "  ${GREEN}${CHECK}${RESET} Edit your prompt anytime and make it smarter" 0.03
  sleep 0.3
  type_text "  ${GREEN}${CHECK}${RESET} Run it for real inside GitHub Copilot" 0.03
  sleep 1.0
  echo ""
  type_text "${DIM}Totally up to you. ${AGENT_NAME} isn't going anywhere either way.${RESET}" 0.03
  echo ""
  echo ""
  sleep 0.3

  printf "  ${BOLD}Do you have a GitHub account?${RESET}\n"
  echo ""

  menu_select \
    "🆕  No, I'd like to claim one (free)" \
    "✅  Yes, I'm all set" \
    "⏭️   Skip this for now"

  local bridge_choice=$MENU_RESULT

  echo ""

  case $bridge_choice in
    0)
      # No account — guide them to claim one
      clear
      echo ""
      echo ""
      printf "  "
      type_text "Here's what's about to happen:" 0.03
      echo ""
      sleep 0.3
      printf "  🌐  Your browser will open to GitHub's free signup page.\n"
      sleep 0.3
      printf "  ✏️   Create your account — takes about a minute.\n"
      sleep 0.3
      printf "  🔙  Then come right back here. This window will be waiting.\n"
      echo ""
      sleep 0.5
      separator
      echo ""
      printf "  ${BOLD}${CYAN}⚡  Don't close this window!${RESET}\n"
      printf "  ${BOLD}${CYAN}    I'll be right here when you get back.${RESET}\n"
      echo ""
      sleep 0.8

      pause_gentle "Ready? Press Enter to open your browser..."

      echo ""

      # Countdown
      local _ci
      for _ci in 3 2 1; do
        printf "\r  ${BOLD}${CYAN}  Opening in %d...${RESET}" "$_ci"
        sleep 0.6
      done
      printf "\r  ${GREEN}${CHECK}  Browser opened!          ${RESET}\n"
      echo ""

      # Open browser
      if command -v open &>/dev/null; then
        open "https://github.com/signup" 2>/dev/null || true
      elif command -v xdg-open &>/dev/null; then
        xdg-open "https://github.com/signup" 2>/dev/null || true
      else
        printf "  Visit: ${CYAN}${BOLD}github.com/signup${RESET}\n"
      fi

      echo ""
      separator
      echo ""
      printf "  ${DIM}Go create your account now.${RESET}\n"
      printf "  ${DIM}When you're done, come back to this terminal.${RESET}\n"
      echo ""

      pause_gentle "Press Enter when you're back..."

      echo ""
      printf "  ${GREEN}${CHECK}${RESET} "
      type_text "Welcome back, ${USER_NAME}!" 0.04
      echo ""
      printf "  "
      type_text "Now run this to connect your account:" 0.03
      echo ""
      printf "  ${CYAN}  gh auth login${RESET}\n"
      echo ""
      ;;
    1)
      # Already has an account
      printf "  ${GREEN}${CHECK}${RESET} Awesome — you're all set.\n"
      echo ""
      sleep 0.3
      printf "  "
      type_text "If you haven't logged in recently, you might need to run:" 0.03
      echo ""
      printf "  ${CYAN}  gh auth login${RESET}\n"
      echo ""
      ;;
    2)
      printf "  "
      type_text "No worries at all. You can do this anytime." 0.03
      echo ""
      printf "  "
      type_text "Everything you built today is saved on your computer." 0.03
      echo ""
      printf "  "
      type_text "When you're ready: ${CYAN}github.com/signup${RESET}" 0.03
      echo ""
      ;;
  esac

  pause_gentle "Press Enter for the final step..."
}

# ---------------------------------------------------------------------------
# Phase 8 — Handoff to Copilot CLI
# ---------------------------------------------------------------------------

handoff_phase() {
  clear
  echo ""
  echo ""

  sleep 1.0
  type_text "One more thing." 0.04
  sleep 1.0
  type_text "Most people think the terminal is for programmers." 0.03
  sleep 0.6
  type_text "You just proved it's for anyone with a good idea." 0.03
  sleep 1.4
  echo ""
  type_text "${AGENT_NAME} is your first build. It doesn't have to be your last." 0.03
  sleep 0.8
  type_text "${CYAN}The Copilot CLI${RESET} is how you build the next one." 0.03
  sleep 0.5
  type_text "Just open this terminal and start talking." 0.03
  sleep 1.6
  echo ""
  type_text "${DIM}Go build things.${RESET}" 0.04
  sleep 1.0
  echo ""
  echo ""
  separator
  echo ""

  printf "  ${BOLD}Here's what to do:${RESET}\n"
  echo ""
  printf "  ${CYAN}1.${RESET} When the new prompt appears, type: ${GREEN}${BOLD}first light${RESET}\n"
  printf "  ${CYAN}2.${RESET} ${AGENT_NAME} will pick up right where we left off\n"
  printf "  ${CYAN}3.${RESET} You'll teach it your writing style and try it for real\n"
  echo ""
  sleep 0.5

  printf "  "
  type_text "Ready?" 0.06
  echo ""

  pause_gentle "Press Enter to meet ${AGENT_NAME}..."

  # --- Final summary screen ---
  clear
  echo ""
  echo ""
  separator
  echo ""
  printf "  ${GREEN}${BOLD}${CHECK} Setup complete!${RESET}\n"
  echo ""
  sleep 1
  printf "  ${BOLD}Your agent:${RESET} ${CYAN}${AGENT_NAME}${RESET}\n"
  sleep 0.5
  printf "  ${BOLD}Your folder:${RESET} ${CYAN}~/my-first-agent/${RESET}\n"
  echo ""
  sleep 1.5
  separator
  echo ""

  # Attempt to launch Copilot CLI directly
  if gh copilot --version &>/dev/null 2>&1; then
    type_text "I'm about to open the Copilot CLI for you." 0.03
    echo ""
    sleep 0.8
    type_text "When you see the prompt, just type: ${GREEN}${BOLD}first light${RESET}" 0.03
    echo ""
    sleep 0.8
    type_text "${AGENT_NAME} will be there, ready to go." 0.03
    echo ""
    echo ""
    sleep 1.5
    echo ""
    printf "  ${COPILOT_GOLD}✨ Become AI native and accelerate your work by using the GitHub Copilot CLI. ✨${RESET}\n"
    echo ""
    sleep 2.0
    pause_gentle "Press Enter to launch the Copilot CLI..."
    echo ""
    exec gh copilot
  else
    # Graceful fallback with manual instructions
    printf "  ${YELLOW}${BOLD}Almost there!${RESET}\n"
    echo ""
    printf "  The Copilot CLI isn't installed yet. Here's how to get it:\n"
    echo ""
    printf "  ${CYAN}  gh auth login${RESET}           ${DIM}← connect your GitHub account${RESET}\n"
    printf "  ${CYAN}  gh extension install github/gh-copilot${RESET}\n"
    printf "  ${CYAN}  gh copilot${RESET}              ${DIM}← start Copilot CLI${RESET}\n"
    echo ""
    printf "  Then type ${GREEN}${BOLD}first light${RESET} to pick up where you left off.\n"
    echo ""
    printf "  ${COPILOT_GOLD}✨ Become AI native and accelerate your work by using the GitHub Copilot CLI. ✨${RESET}\n"
    echo ""
    printf "  ${DIM}Everything you built is saved. Come back anytime.${RESET}\n"
    echo ""
  fi
}

# ---------------------------------------------------------------------------
# Main Flow
# ---------------------------------------------------------------------------

main() {
  if [ "${COPILOT_FIRST_LIGHT_BOOTSTRAP:-}" = "1" ]; then
    # Launched from install.sh — cinematic and installs already done, don't clear
    welcome_phase
  else
    # Standalone run — do everything
    install_phase
    welcome_phase
  fi
  pick_agent_phase
  name_agent_phase
  pick_personality_phase
  build_phase
  show_creation_phase
  demo_phase
  bridge_phase
  handoff_phase
}

# Only run main if not being sourced for functions
if [ "${1:-}" != "--functions-only" ]; then
  main "$@"
fi
