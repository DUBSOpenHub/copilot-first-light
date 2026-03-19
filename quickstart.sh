#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# First Light — Your First AI Helper
# ============================================================================
# Run with: curl -fsSL https://raw.githubusercontent.com/.../quickstart.sh | bash
#
# This script guides a complete beginner through building their first
# AI helper — no coding experience needed. It installs what's needed,
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
BOLD="\033[1m"
DIM="\033[2m"
ITALIC="\033[3m"
RESET="\033[0m"
CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
MAGENTA="\033[35m"
BLUE="\033[34m"
WHITE="\033[97m"
RED="\033[31m"

BOX_TL="╔" BOX_TR="╗" BOX_BL="╚" BOX_BR="╝"
BOX_H="═" BOX_V="║"
LINE_H="─"
CHECK="✓"

# ---------------------------------------------------------------------------
# State variables — filled in during the interactive flow
# ---------------------------------------------------------------------------
USER_NAME=""
HELPER_TYPE=""
HELPER_TYPE_INDEX=0
HELPER_NAME=""
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
  local selected=0
  local count=${#options[@]}
  tput civis 2>/dev/null || true
  local i=0
  while [ $i -lt $count ]; do
    if [ $i -eq $selected ]; then
      printf "  ${GREEN}${BOLD}  ❯ ${options[$i]}${RESET}\n"
    else
      printf "  ${DIM}    ${options[$i]}${RESET}\n"
    fi
    i=$(( i + 1 ))
  done
  while true; do
    local key
    IFS= read -r -s -n 1 key
    if [[ "$key" == $'\x1b' ]]; then
      read -r -s -n 2 -t 1 key || true
      case "$key" in
        '[A') [ $selected -gt 0 ] && selected=$(( selected - 1 )) ;;
        '[B') [ $selected -lt $(( count - 1 )) ] && selected=$(( selected + 1 )) ;;
      esac
    elif [[ "$key" == "" ]]; then
      break
    fi
    printf "\033[${count}A"
    i=0
    while [ $i -lt $count ]; do
      printf "\033[2K"
      if [ $i -eq $selected ]; then
        printf "  ${GREEN}${BOLD}  ❯ ${options[$i]}${RESET}\n"
      else
        printf "  ${DIM}    ${options[$i]}${RESET}\n"
      fi
      i=$(( i + 1 ))
    done
  done
  tput cnorm 2>/dev/null || true
  MENU_RESULT=$selected
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
    show_progress "Copilot CLI ready" 1
  else
    show_progress "Installing Copilot CLI..." 2
    gh extension install github/gh-copilot &>/dev/null 2>&1 || true
    if gh copilot --version &>/dev/null 2>&1; then
      show_progress "Copilot CLI installed" 1
    else
      show_progress "Copilot CLI — we'll finish this later" 1
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
# Phase 1 — Welcome
# ---------------------------------------------------------------------------

welcome_phase() {
  clear
  echo ""
  echo ""

  echo -e "${BOLD}${WHITE}  Hey there.${RESET}" | box

  sleep 0.8
  printf "  "
  type_text "You're about to build your first AI helper." 0.04
  echo ""
  sleep 0.5
  printf "  "
  type_text "It takes about five minutes. No coding needed." 0.03
  echo ""
  sleep 0.5
  printf "  "
  type_text "I'll walk you through every step." 0.03
  echo ""
  echo ""
  separator
  echo ""
  sleep 0.3

  printf "  ${BOLD}First — what's your name?${RESET}\n"
  echo ""
  printf "  ${CYAN}> ${RESET}"
  read -r USER_NAME

  if [ -z "$USER_NAME" ]; then
    USER_NAME="friend"
  fi

  USER_NAME="$(to_upper_first "$USER_NAME")"

  echo ""
  printf "  "
  type_text "Nice to meet you, ${USER_NAME}. Let's build something together." 0.03
  echo ""
  pause_gentle "Press Enter when you're ready..."
}

# ---------------------------------------------------------------------------
# Phase 2 — Pick Your Helper
# ---------------------------------------------------------------------------

pick_helper_phase() {
  clear
  echo ""
  echo ""
  printf "  ${BOLD}${WHITE}What should your helper do?${RESET}\n"
  echo ""
  printf "  "
  type_text "Pick the one that sounds most useful to you." 0.03
  echo ""
  printf "  ${DIM}(Use arrow keys to move, Enter to select)${RESET}\n"
  echo ""

  menu_select \
    "📧  Help me write better emails" \
    "📋  Summarize long documents" \
    "💡  Brainstorm ideas with me" \
    "🎨  Something else entirely"

  HELPER_TYPE_INDEX=$MENU_RESULT

  case $HELPER_TYPE_INDEX in
    0) HELPER_TYPE="email" ;;
    1) HELPER_TYPE="summarize" ;;
    2) HELPER_TYPE="brainstorm" ;;
    3) HELPER_TYPE="custom" ;;
  esac

  local choice_labels=("writing better emails" "summarizing documents" "brainstorming ideas" "something custom")
  local chosen="${choice_labels[$HELPER_TYPE_INDEX]}"

  echo ""
  printf "  ${GREEN}${CHECK}${RESET} Great choice — ${BOLD}${chosen}${RESET}.\n"
  echo ""
  sleep 0.8
}

# ---------------------------------------------------------------------------
# Phase 3 — Name Your Helper
# ---------------------------------------------------------------------------

name_helper_phase() {
  clear
  echo ""
  echo ""
  printf "  ${BOLD}${WHITE}Every helper needs a name.${RESET}\n"
  echo ""
  printf "  "
  type_text "It can be anything. Serious, silly, whatever feels right." 0.03
  echo ""

  local suggestions
  case $HELPER_TYPE in
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
  read -r HELPER_NAME

  if [ -z "$HELPER_NAME" ]; then
    HELPER_NAME="Buddy"
  fi

  HELPER_NAME="$(to_upper_first "$HELPER_NAME")"

  echo ""
  printf "  "
  type_text "${HELPER_NAME}. I like it." 0.04
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
  printf "  ${BOLD}${WHITE}How should ${HELPER_NAME} talk?${RESET}\n"
  echo ""
  printf "  "
  type_text "This sets the tone for everything it writes." 0.03
  echo ""
  printf "  ${DIM}(Use arrow keys to move, Enter to select)${RESET}\n"
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
  printf "  ${GREEN}${CHECK}${RESET} ${HELPER_NAME} will be ${BOLD}${personality_labels[$PERSONALITY_INDEX]}${RESET}.\n"
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
  printf "  ${BOLD}${WHITE}Building ${HELPER_NAME}...${RESET}\n"
  echo ""
  separator
  echo ""

  # Create the agent directory
  mkdir -p "$AGENT_DIR" 2>/dev/null || true

  # Compose the system prompt based on helper type
  local type_instruction=""
  case $HELPER_TYPE in
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
      type_instruction="You're a flexible AI helper. You adapt to whatever task the user needs, always being clear and useful."
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

  show_progress "Creating a folder for ${HELPER_NAME}" 2

  # Write the agent prompt file
  cat > "$AGENT_DIR/prompt.md" << AGENT_EOF
# ${HELPER_NAME}

${type_instruction}

## Personality
${personality_instruction}

## Rules
- Always be helpful and clear
- If you're not sure what the user wants, ask
- Keep your responses focused and useful
- Use plain language — no jargon
AGENT_EOF

  show_progress "Writing ${HELPER_NAME}'s personality" 2

  # Write a sample input file based on helper type
  local sample_input=""
  case $HELPER_TYPE in
    email)
      sample_input="Subject: Following up on our meeting\n\nHey — just wanted to follow up on what we talked about yesterday. I think the timeline works but I have a couple questions about the budget. Can we chat Thursday?"
      ;;
    summarize)
      sample_input="Paste any long text here and ${HELPER_NAME} will summarize it for you.\n\nTry it with an article, a long email chain, meeting notes, or any document that needs a quick summary."
      ;;
    brainstorm)
      sample_input="Topic: Planning a team offsite\n\nWe need ideas for a two-day team offsite for 15 people. Budget is moderate. Goal is team bonding plus strategic planning. The team is mostly remote."
      ;;
    custom)
      sample_input="Write anything here and ${HELPER_NAME} will help.\n\nYou can ask it to write, edit, summarize, brainstorm, explain, or anything else you need."
      ;;
  esac

  printf "%b" "$sample_input" > "$AGENT_DIR/sample-input.txt"
  show_progress "Adding a sample for you to try" 1

  # Save state for the Copilot CLI skill to read later
  cat > "$STATE_FILE" << STATE_EOF
USER_NAME="${USER_NAME}"
HELPER_NAME="${HELPER_NAME}"
HELPER_TYPE="${HELPER_TYPE}"
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
  type_text "${HELPER_NAME} exists now — on this machine, in a real folder you can open." 0.03
  sleep 0.8
  type_text "You didn't install an app. You ${BOLD}built${RESET} something." 0.03
  sleep 0.6
  type_text "A prompt file, a config, a structure — the same pieces a developer would create." 0.03
  sleep 1.4
  type_text "${DIM}You just didn't need to be one to do it.${RESET}" 0.03
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
  printf "  ${DIM}├── ${RESET}prompt.md       ${DIM}← ${HELPER_NAME}'s personality & instructions${RESET}\n"
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
  type_text "Now you have an AI helper called ${BOLD}${HELPER_NAME}${RESET} that follows instructions you wrote." 0.03
  sleep 1.4
  echo ""
  type_text "Not instructions someone gave you." 0.03
  sleep 0.5
  type_text "${BOLD}Your${RESET} words. ${BOLD}Your${RESET} rules. ${BOLD}Your${RESET} helper." 0.03
  sleep 1.6
  echo ""
  type_text "That feeling right now — that little ${CYAN}wait, really?${RESET} — remember it." 0.03
  sleep 0.8
  type_text "That's what building feels like." 0.03
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

  printf "  ${BOLD}${WHITE}Let's see ${HELPER_NAME} in action.${RESET}\n"
  echo ""
  sleep 0.5
  printf "  "
  type_text "Here's what it would do with your sample input:" 0.03
  echo ""
  separator
  echo ""

  # Build a mock response based on type + personality
  local mock_response=""
  case "${HELPER_TYPE}-${PERSONALITY}" in
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

  printf "  ${DIM}┌─ ${HELPER_NAME}'s response ─────────────────────────┐${RESET}\n"
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
  type_text "That's ${HELPER_NAME} doing its thing." 0.03
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
  type_text "Right now, ${HELPER_NAME} lives on this computer." 0.03
  sleep 0.6
  type_text "Which is fine — it works. But it's a little like writing a song and never saving the file." 0.03
  sleep 1.0
  echo ""
  type_text "GitHub is where people keep the things they build." 0.03
  sleep 0.5
  type_text "Developers use it. And now — people like you do too." 0.03
  sleep 1.0
  echo ""
  type_text "If you grab a free GitHub account, you can:" 0.03
  sleep 0.4
  type_text "  ${GREEN}${CHECK}${RESET} Save ${HELPER_NAME} so it's yours permanently" 0.03
  sleep 0.3
  type_text "  ${GREEN}${CHECK}${RESET} Edit your prompt anytime and make it smarter" 0.03
  sleep 0.3
  type_text "  ${GREEN}${CHECK}${RESET} Run it for real inside GitHub Copilot" 0.03
  sleep 1.0
  echo ""
  type_text "${DIM}Totally up to you. ${HELPER_NAME} isn't going anywhere either way.${RESET}" 0.03
  echo ""
  echo ""
  sleep 0.3

  printf "  ${BOLD}Do you have a GitHub account?${RESET}\n"
  echo ""

  menu_select \
    "✅  Yes, I'm all set" \
    "🆕  No, I'd like to claim one (free)" \
    "⏭️   Skip this for now"

  local bridge_choice=$MENU_RESULT

  echo ""

  case $bridge_choice in
    0)
      printf "  ${GREEN}${CHECK}${RESET} Awesome — you're all set.\n"
      echo ""
      sleep 0.3
      printf "  "
      type_text "If you haven't logged in recently, you might need to run:" 0.03
      echo ""
      printf "  ${CYAN}  gh auth login${RESET}\n"
      echo ""
      ;;
    1)
      printf "  "
      type_text "Here's what to do:" 0.03
      echo ""
      echo ""
      printf "  ${BOLD}1.${RESET} Open this link: ${CYAN}${BOLD}github.com/signup${RESET}\n"
      printf "  ${BOLD}2.${RESET} Pick a username (that's your developer name now!)\n"
      printf "  ${BOLD}3.${RESET} Come back here when you're done\n"
      echo ""
      sleep 0.3
      printf "  ${DIM}It takes about 2 minutes. Totally free. No credit card.${RESET}\n"
      echo ""

      # Try to open the browser automatically
      if command -v open &>/dev/null; then
        open "https://github.com/signup" 2>/dev/null || true
      elif command -v xdg-open &>/dev/null; then
        xdg-open "https://github.com/signup" 2>/dev/null || true
      fi

      pause_gentle "Press Enter when you're back..."

      echo ""
      printf "  ${GREEN}${CHECK}${RESET} "
      type_text "Welcome to GitHub, ${USER_NAME}." 0.04
      echo ""
      printf "  "
      type_text "Now run this to connect your account:" 0.03
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
  type_text "${HELPER_NAME} is your first build. It doesn't have to be your last." 0.03
  sleep 0.8
  type_text "Next time you open this window, try typing what you want to happen." 0.03
  sleep 0.5
  type_text "You might be surprised what listens." 0.03
  sleep 1.6
  echo ""
  type_text "${DIM}This terminal will be here whenever you're ready to come back.${RESET}" 0.03
  sleep 0.6
  type_text "Go build things." 0.04
  sleep 1.0
  echo ""
  echo ""
  separator
  echo ""

  printf "  ${BOLD}Here's what to do:${RESET}\n"
  echo ""
  printf "  ${CYAN}1.${RESET} When the new prompt appears, type: ${GREEN}${BOLD}first light${RESET}\n"
  printf "  ${CYAN}2.${RESET} ${HELPER_NAME} will pick up right where we left off\n"
  printf "  ${CYAN}3.${RESET} You'll teach it your writing style and try it for real\n"
  echo ""
  sleep 0.5

  printf "  "
  type_text "Ready?" 0.06
  echo ""

  pause_gentle "Press Enter to meet ${HELPER_NAME}..."

  # --- Final summary screen ---
  clear
  echo ""
  echo ""
  separator
  echo ""
  printf "  ${GREEN}${BOLD}${CHECK} Setup complete!${RESET}\n"
  echo ""
  printf "  ${BOLD}Your helper:${RESET} ${CYAN}${HELPER_NAME}${RESET}\n"
  printf "  ${BOLD}Your folder:${RESET} ${CYAN}~/my-first-agent/${RESET}\n"
  printf "  ${BOLD}Your state:${RESET}  ${CYAN}~/.first-light-state${RESET}\n"
  echo ""
  separator
  echo ""

  # Attempt to launch Copilot CLI directly
  if gh copilot --version &>/dev/null 2>&1; then
    printf "  ${BOLD}Launching Copilot CLI...${RESET}\n"
    printf "  ${DIM}Type ${RESET}${GREEN}first light${RESET}${DIM} to continue your journey.${RESET}\n"
    echo ""
    sleep 1.5
    exec gh copilot
  else
    # Graceful fallback with manual instructions
    printf "  ${YELLOW}${BOLD}Almost there!${RESET}\n"
    echo ""
    printf "  Copilot CLI isn't installed yet. Here's how to get it:\n"
    echo ""
    printf "  ${CYAN}  gh auth login${RESET}           ${DIM}← connect your GitHub account${RESET}\n"
    printf "  ${CYAN}  gh extension install github/gh-copilot${RESET}\n"
    printf "  ${CYAN}  gh copilot${RESET}              ${DIM}← start Copilot CLI${RESET}\n"
    echo ""
    printf "  Then type ${GREEN}${BOLD}first light${RESET} to pick up where you left off.\n"
    echo ""
    printf "  ${DIM}Everything you built is saved. Come back anytime.${RESET}\n"
    echo ""
  fi
}

# ---------------------------------------------------------------------------
# Main Flow
# ---------------------------------------------------------------------------

main() {
  install_phase
  welcome_phase
  pick_helper_phase
  name_helper_phase
  pick_personality_phase
  build_phase
  show_creation_phase
  demo_phase
  bridge_phase
  handoff_phase
}

main "$@"
