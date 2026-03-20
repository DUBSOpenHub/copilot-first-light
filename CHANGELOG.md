# 📋 Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2026-03-20

### Added
- 🎓 **Copilot CLI Quickstart auto-install** — installs the quickstart skill at the end of First Light so users flow directly into a guided Copilot CLI tutorial
- 🔧 **CI workflow** (`.github/workflows/ci.yml`) — validates `bash -n` on both shell scripts for every push and PR
- 🛡️ **CodeQL workflow** (`.github/workflows/codeql.yml`) — weekly security scanning

### Changed
- 🖥️ **Show folder path in Done section** — users now see `~/my-first-agent/` immediately when told their files were created
- ✏️ **Welcome text** — "This is where you can build" (added missing "can")
- 📝 **Done section text** — changed to "These files now live on your computer" for clarity
- 🎯 **Removed "Something else entirely" option** — three focused agent types (email, summarize, brainstorm) instead of a hollow generic fourth option
- ⌨️ **Typewriter effect for prompt.md** — file contents now type out line by line instead of appearing as a wall of text
- 💬 **Softened bridge phase tone** — celebrates what users built instead of implying it's incomplete
- ⏸️ **Added pause after teaching moment** — "Your words. Your rules. Your agent." now has a gate before the demo starts
- 📢 **Linux sudo transparency** — shows the user what command requires admin access instead of running silently

### Fixed
- 🛡️ **Input sanitization** — `sanitize_input()` strips shell-dangerous characters (`"`, `'`, `` ` ``, `$`, `\`) from all user input at entry point, preventing heredoc injection and state file corruption
- 🔒 **TTY guard** — `exec < /dev/tty` now checks `/dev/tty` exists before redirecting, shows friendly error in headless environments
- 🔗 **Hardcoded path references** — replaced remaining `~/my-first-agent/` literals with dynamic `${AGENT_DIR##*/}`

### Removed
- 🎨 **"Something else entirely" agent option** — generic custom agent that produced vague prompts without asking what the user wanted

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
