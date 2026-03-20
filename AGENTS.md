# Agents — Copilot First Light

This document is the authoritative guide for AI agents and human contributors working in this repository. Read it before making any changes.

---

## Overview

Copilot First Light is a non-developer onboarding experience for the GitHub Copilot CLI. It has two parts that work together:

1. **`quickstart.sh`** — An animated, interactive bash script that walks a complete beginner through building their first AI agent in ~5 minutes. No coding required.
2. **Copilot CLI skill** (`.github/skills/copilot-first-light/SKILL.md`) — Picks up where the quickstart left off, using the saved state to personalize the deeper CLI experience.

---

## File Ownership Map

Every file in this repo has a specific role. **Do not move, rename, or repurpose files without updating this map.**

| File / Path | Role | Mutable? |
|-------------|------|----------|
| `quickstart.sh` | Main animated bash experience. Entry point for all users. | ✅ Yes — carefully |
| `install.sh` | Installs Homebrew, GitHub CLI, and the Copilot extension for zero-setup users. | ✅ Yes — carefully |
| `README.md` | Public-facing landing page. Plain language only. | ✅ Yes |
| `AGENTS.md` | This file. Architecture guide for agents and contributors. | ✅ Yes |
| `agents/copilot-first-light.agent.md` | Agent personality/system prompt for the Copilot CLI companion. | ✅ Yes |
| `.github/skills/copilot-first-light/SKILL.md` | The Copilot CLI skill that runs when user types "first light". Reads `~/.first-light-state`. | ✅ Yes — carefully |
| `LICENSE` | MIT License. Do not change the year or org name. | ⛔ No |
| `SECURITY.md` | Vulnerability reporting policy and privacy practices. | ✅ Yes |
| `CONTRIBUTING.md` | How to contribute. Enforces bash `-n` validation and "claim" language rules. | ✅ Yes |
| `CODE_OF_CONDUCT.md` | Contributor Covenant v2.1. | ⛔ No |
| `CHANGELOG.md` | Release history. Update under `[Unreleased]` for every PR. | ✅ Yes |
| `TESTING.md` | Conversation playbooks and QA checklist. | ✅ Yes |
| `.gitignore` | Standard ignores for shell/Node. | ✅ Yes |
| `.github/workflows/ci.yml` | CI — validates `bash -n` on push and PR. | ✅ Yes |
| `.github/workflows/codeql.yml` | CodeQL security scanning (weekly + push/PR). | ✅ Yes |
| `.github/CODEOWNERS` | All files owned by @DUBSOpenHub. | ⛔ No |
| `.github/dependabot.yml` | Dependabot config. | ✅ Yes |

### What Gets Created on the User's Machine (not in this repo)

When a user runs `quickstart.sh`, these files are created **locally on their computer**:

```
~/my-first-agent/
├── prompt.md         ← Agent instructions and personality (user-owned)
└── sample-input.txt  ← Example input to try (user-owned)
~/.first-light-state  ← State file read by the Copilot CLI skill
```

These paths are hardcoded in `quickstart.sh`. If you change them, update the skill's state-reading logic too.

---

## Architecture

```
copilot-first-light/
├── quickstart.sh                              ← Entry point (bash, animated)
├── install.sh                                 ← Zero-setup installer
├── README.md                                  ← Landing page
├── AGENTS.md                                  ← This file
├── agents/
│   └── copilot-first-light.agent.md           ← Companion agent personality
└── .github/
    ├── CODEOWNERS                             ← * @DUBSOpenHub
    ├── dependabot.yml                         ← Dependabot config
    ├── workflows/
    │   ├── ci.yml                             ← bash -n validation
    │   └── codeql.yml                         ← Security scanning
    └── skills/
        └── copilot-first-light/
            └── SKILL.md                       ← Copilot CLI skill
```

---

## Change Rules

### Shell Scripts (`quickstart.sh`, `install.sh`)

- **All changes must pass `bash -n`** — run `bash -n quickstart.sh && bash -n install.sh` before every commit. Zero warnings required. CI enforces this automatically.
- **All user input is sanitized** — `sanitize_input()` strips shell-dangerous characters (`"`, `'`, `` ` ``, `$`, `\`) from `USER_NAME` and `AGENT_NAME` at entry point. Never use raw `read` values in heredocs or printf without sanitization.
- Never pipe from the internet directly to `bash` without user confirmation.
- Preserve the animated, emoji-rich UX. This is not a utility script — it's an experience.
- The state file path (`~/.first-light-state`) is a contract between `quickstart.sh` and `SKILL.md`. Change both if you change either.
- At the end of the flow, `quickstart.sh` installs the [Copilot CLI Quickstart](https://github.com/DUBSOpenHub/copilot-cli-quickstart) skill and launches `gh copilot`. This creates a seamless onboarding chain.

### SKILL.md

- Must read `~/.first-light-state` to get the agent name and purpose before greeting the user.
- If no state file exists, gracefully ask if the user has run the quickstart.
- Never use developer jargon ("repo", "clone", "fork", "commit") without a plain-language explanation.
- Never use "sign up" — always use **"claim"**.

### All User-Facing Text (scripts, skill, README)

- **No "sign up"** — always **"claim"** (e.g., "claim your free Copilot access")
- **No unexplained jargon** — assume the reader has never used a terminal
- **Emojis throughout** — warm, encouraging tone throughout
- **One thing at a time** — don't present multiple options or steps simultaneously

---

## Common Pitfalls

| Pitfall | Consequence | Prevention |
|---------|-------------|------------|
| Skipping `bash -n` validation | Broken experience for users, script may fail silently | Always run `bash -n` before committing shell changes |
| Using "sign up" instead of "claim" | Inconsistent language, may be flagged in review | `grep -r "sign up" .` must return zero results |
| Changing `~/.first-light-state` path in only one file | Skill can't read state, user gets broken bridge flow | Search for all references: `grep -r "first-light-state" .` |
| Adding jargon to quickstart output | Non-developers get confused and drop off | Have someone non-technical read the output before merging |
| Modifying `CODE_OF_CONDUCT.md` | Community standards drift | This file is frozen — open an issue to discuss changes |
| Adding credentials or tokens to any file | Security vulnerability | Never. Run secret scanning before merging. |
| Breaking the `~/my-first-agent/` creation | Users finish quickstart with no files to show | Always test the full quickstart flow end-to-end, not just syntax |

---

## Running It

**First time (fresh install):**
```bash
bash install.sh   # if starting from zero
bash quickstart.sh
```

**Returning user:**
Open the Copilot CLI and type `first light` — the skill picks up where the quickstart left off.

**Resetting completely:**
```bash
rm -rf ~/my-first-agent/ ~/.first-light-state
bash quickstart.sh
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full guide, including the bash validation requirement and language rules. See [TESTING.md](TESTING.md) for conversation playbooks covering the animated intro, bridge flow, and Copilot CLI skill.
