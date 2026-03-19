# Copilot Instructions

This repository is **Copilot First Light** — a non-developer onboarding experience for the GitHub Copilot CLI.

## Key Rules

- **Audience:** Complete non-developers who have never used a terminal.
- **Language:** Warm, friendly, plain English. No jargon.
- **"Agent" not "helper":** Always refer to what the user builds as an "agent."
- **"The Copilot CLI":** Always include "the" before "Copilot CLI."
- **"Claim" not "sign up":** Never say "sign up," "register," or "create account." Say "claim your agent" or "save your creation."
- **Bash 3.2+:** All shell scripts must be compatible with macOS's default bash.
- **Pipe-safe:** Scripts must work via `curl | bash` with `/dev/tty` restoration.
- **No raw errors:** Never show error messages to the user. Use friendly fallbacks.

## File Ownership

| File | Purpose | Change Rules |
|------|---------|-------------|
| `install.sh` | Bootstrap installer | Must pass `bash -n`. Never prompt the user. |
| `quickstart.sh` | Animated TUI experience | Must pass `bash -n`. Test full flow after changes. |
| `SKILL.md` | Copilot CLI skill | Reinstall to `~/.copilot/skills/` after changes. |
| `agents/copilot-first-light.agent.md` | Agent config | Keep persona warm and plain. |

## Testing

Run `bash -n install.sh && bash -n quickstart.sh` before any PR.
See [TESTING.md](../../TESTING.md) for conversation playbooks.
