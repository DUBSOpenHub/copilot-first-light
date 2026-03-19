# 📋 Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-03-18

### Added
- 🚀 Initial release of Copilot First Light
- 🎬 **Animated quickstart** (`quickstart.sh`) — a friendly, emoji-rich terminal experience that guides non-developers through building their first AI agent in ~5 minutes
  - Interactive prompts to pick agent purpose, name, and personality
  - Real-time "building" animation as agent files are created
  - Saves choices to `~/.first-light-state` for the Copilot CLI skill to pick up
  - Creates `~/my-first-agent/prompt.md` and `~/my-first-agent/sample-input.txt`
- 🔧 **Install script** (`install.sh`) — installs Homebrew, GitHub CLI, and Copilot CLI extension for users starting from zero
- 🤖 **Copilot CLI skill** (`.github/skills/copilot-first-light/SKILL.md`) — picks up where the quickstart left off
  - Reads saved agent choices and welcomes users back by name
  - Teaches the agent the user's writing style from a provided sample
  - Demonstrates real AI output customized to the user's voice
  - Guides iterative tuning until the output feels right
  - Reveals the "what you actually built" moment
- 👤 **Agent personality config** (`agents/copilot-first-light.agent.md`) — companion agent for the skill experience
- 📖 **README.md** — plain-language landing page with zero-jargon setup instructions
- 📋 **AGENTS.md** — file ownership map and architecture guide for contributors and AI agents
- 🔒 **SECURITY.md** — vulnerability reporting policy and privacy practices
- 🤝 **CODE_OF_CONDUCT.md** — Contributor Covenant v2.1
- 🛠️ **CONTRIBUTING.md** — contributor guide with bash validation rules and language standards
- 🧪 **TESTING.md** — conversation playbooks for the animated intro, bridge flow, and Copilot CLI skill
- 📄 **LICENSE** — MIT License, copyright 2026 DUBSOpenHub
- 🙈 **.gitignore** — standard ignores for shell/Node projects
- 👥 **.github/CODEOWNERS** — all files owned by @DUBSOpenHub
- 🤖 **.github/dependabot.yml** — Dependabot configuration
