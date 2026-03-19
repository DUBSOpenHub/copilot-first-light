# 🧪 Testing Guide

This document describes how to verify that Copilot First Light works correctly from start to finish.

First Light has two parts — the animated terminal quickstart (`quickstart.sh`) and the Copilot CLI skill (`.github/skills/copilot-first-light/SKILL.md`). Both need to be tested before any PR is merged.

---

## 🎮 How to Test Locally

### Testing the Quickstart Script

1. **Validate bash syntax first** (no excuses — this must pass):
   ```bash
   bash -n quickstart.sh && bash -n install.sh && echo "✅ Syntax OK"
   ```

2. **Run the full experience**:
   ```bash
   bash quickstart.sh
   ```

3. **Verify the output files were created**:
   ```bash
   ls ~/my-first-agent/
   # Expected: prompt.md  sample-input.txt
   cat ~/.first-light-state
   # Expected: JSON or key=value with agent name, purpose, personality
   ```

### Testing the Copilot CLI Skill

1. **Register the skill** in a Copilot CLI session:
   ```
   /skills add ./
   ```
   Or if already installed:
   ```
   /skills reload
   ```

2. **Run each playbook** below and verify the expected behavior.

3. **Check the QA checklist** at the bottom before submitting a PR.

---

## 📋 Conversation Playbooks

### Playbook 1: Animated Intro (quickstart.sh)

| Step | Action | Expected Behavior |
|------|--------|-------------------|
| 1 | Run `bash quickstart.sh` | Animated welcome banner appears with emoji and color |
| 2 | Choose agent purpose from menu | Menu is readable, selection works with arrow keys or number |
| 3 | Enter a name for the agent | Prompt is friendly, accepts any text |
| 4 | Choose a personality | Options are described in plain language (no jargon) |
| 5 | Watch the "build" animation | Files appear to be created step-by-step with visual feedback |
| 6 | Reach the handoff screen | Screen explains next step ("open Copilot CLI and type 'first light'") without using developer jargon |
| 7 | Check `~/my-first-agent/` | `prompt.md` and `sample-input.txt` both exist and contain the user's choices |
| 8 | Check `~/.first-light-state` | State file exists and contains agent name, purpose, and personality |

### Playbook 2: Bridge Flow (Quickstart → Skill Handoff)

| Step | Action | Expected Behavior |
|------|--------|-------------------|
| 1 | Complete quickstart with agent named "Alex" | State saved to `~/.first-light-state` |
| 2 | Open Copilot CLI | Copilot CLI session starts normally |
| 3 | Type `first light` | Skill activates, reads state file, greets user using "Alex" |
| 4 | Skill asks for a writing sample | Instructions are plain-language ("paste a few sentences you've written") |
| 5 | Provide a short writing sample | Skill processes it and generates a demo output in the user's style |
| 6 | User says output doesn't feel right | Skill offers to adjust tone/style, not technical settings |
| 7 | User approves the output | Skill reveals the "what you built" moment with encouragement |

### Playbook 3: Copilot CLI Skill — First-Time User

| Step | You Say | Expected Behavior |
|------|---------|-------------------|
| 1 | `first light` | Skill reads `~/.first-light-state` and welcomes user back by agent name |
| 2 | *(no state file exists)* | Skill gracefully asks if they've run the quickstart, offers to walk through it |
| 3 | Provide a writing sample | Skill teaches the agent the user's voice |
| 4 | `show me what it can do` | Skill generates a sample output using the agent's prompt and writing style |
| 5 | `make it funnier` | Skill adjusts and regenerates — no mention of "parameters" or "prompts" |
| 6 | `that's perfect` | Skill shows a warm summary of what was accomplished |

### Playbook 4: Edge Cases

| Step | You Say / Action | Expected Behavior |
|------|-----------------|-------------------|
| 1 | Run quickstart, press Ctrl+C mid-way | Script exits cleanly, no partial state written |
| 2 | `first light` with no state file | Graceful fallback — asks if they've run the quickstart yet |
| 3 | Provide an empty writing sample | Skill handles gracefully, asks for a real example |
| 4 | `asdfghjkl` | Skill asks to clarify, suggests saying "first light" to start |
| 5 | Run quickstart twice | Second run offers to reset or update existing agent |

### Playbook 5: Language & Tone Check

| Criterion | How to Verify |
|-----------|---------------|
| No jargon | Scan `quickstart.sh` output and skill responses for: "repo", "clone", "fork", "commit", "pull request", "API" — none should appear without plain-language explanation |
| No "sign up" | `grep -r "sign up" .` — must return zero results |
| Uses "claim" | Anywhere Copilot access is mentioned, the word "claim" is used |
| Emojis throughout | Every major section of quickstart output uses at least one emoji |
| No assumed knowledge | A person who has never used a terminal should be able to complete the full flow |

---

## ✅ QA Checklist

Before submitting a PR, verify:

- [ ] 🔤 `bash -n quickstart.sh` passes with zero warnings
- [ ] 🔤 `bash -n install.sh` passes with zero warnings
- [ ] 🎬 Quickstart runs end-to-end on a clean terminal (no prior state)
- [ ] 📁 `~/my-first-agent/prompt.md` and `sample-input.txt` are created correctly
- [ ] 💾 `~/.first-light-state` contains the expected values
- [ ] 🤝 Bridge flow works: skill reads state and greets by agent name
- [ ] ✍️ Writing sample flow works: skill generates output in user's voice
- [ ] 🎯 "What you built" reveal is warm and non-technical
- [ ] 🚫 No "sign up" language anywhere — always "claim"
- [ ] 🐣 No unexplained developer jargon in any user-facing text
- [ ] ⚠️ Edge cases handled gracefully (no state file, empty input, Ctrl+C)
- [ ] 🤝 Tone is friendly, encouraging, and uses emojis throughout

---

## 🔍 Shell Script Validation

Run before every PR:

```bash
# Syntax check
bash -n quickstart.sh && echo "✅ quickstart.sh OK"
bash -n install.sh    && echo "✅ install.sh OK"

# Check for forbidden language
grep -rn "sign up" . --include="*.sh" --include="*.md" && echo "❌ Found 'sign up'" || echo "✅ No 'sign up' found"

# Check state file creation
rm -f ~/.first-light-state
bash quickstart.sh   # complete the flow
test -f ~/.first-light-state && echo "✅ State file created" || echo "❌ State file missing"
```

---

## 📊 Coverage Matrix

| Feature | Playbook | Status |
|---------|----------|--------|
| Animated intro (quickstart.sh) | 1 | 🧪 |
| Bridge flow (quickstart → skill) | 2 | 🧪 |
| First-time skill experience | 3 | 🧪 |
| Edge cases & error handling | 4 | 🧪 |
| Language & tone compliance | 5 | 🧪 |
| Bash syntax validation | Shell Validation | 🧪 |
| "claim" language check | 5 | 🧪 |
| No state file graceful fallback | 4.2 | 🧪 |
