# 🤝 Contributing to Copilot First Light

First off — **thank you!** 💜 Every contribution makes this experience better for the next person taking their first step with GitHub Copilot CLI.

## 🎯 Ways to Contribute

### 💡 No Code Required!

You don't need to write code to help. Open an [Issue](https://github.com/DUBSOpenHub/copilot-first-light/issues) for any of these:

- 🐛 **Report a bug** — Did the quickstart confuse you or break? Tell us!
- 💡 **Suggest an improvement** — What would have made your first experience better?
- ✏️ **Fix a typo** — Spotted a mistake? Let us know!
- 🌍 **Translation help** — Want to help non-English speakers?
- 🎨 **UX feedback** — Was something intimidating or unclear?

### 🧑‍💻 Code Contributions

1. **Fork** this repo
2. **Create a branch**: `git checkout -b my-improvement`
3. **Make your changes** — see the development guide below
4. **Test your changes** — see [TESTING.md](TESTING.md)
5. **Open a PR** — describe what you changed and why

## 🛠️ Development Setup

### Prerequisites

- [GitHub Copilot CLI](https://github.com/github/copilot-cli) installed
- An active [Copilot subscription](https://github.com/features/copilot/plans) — **claim yours** at [github.com/features/copilot/plans](https://github.com/features/copilot/plans)
- `bash` (macOS or Linux; Windows users: use WSL2 or Git Bash)

### Local Testing

1. Clone the repo:
   ```bash
   git clone https://github.com/DUBSOpenHub/copilot-first-light.git
   cd copilot-first-light
   ```

2. Run the full experience:
   ```bash
   bash quickstart.sh
   ```

3. Test the Copilot CLI skill in a Copilot CLI session:
   ```
   first light
   ```

4. Verify your changes against the [TESTING.md](TESTING.md) playbooks.

## 📝 What Makes a Good Contribution

- 🎉 **Keep the tone warm and welcoming** — emojis welcome, jargon not!
- 🐣 **Assume zero prior experience** — this is someone's first time. Explain everything.
- ✅ **All bash must pass `bash -n`** — run `bash -n quickstart.sh` and `bash -n install.sh` before submitting. Zero warnings required.
- 🚫 **Never use "sign up"** — always use **"claim"** (e.g., "claim your free Copilot access")
- 🔑 **No secrets ever** — no tokens, API keys, or credentials anywhere in the repo
- 🌱 **Non-developer friendly language** — avoid terms like "clone", "repo", "fork" without explaining them; avoid "run this command" without showing exactly what to type
- 🧪 **Test the full flow before PR** — run `quickstart.sh` end-to-end AND test the Copilot CLI skill with the playbooks in TESTING.md

## 📋 Pull Request Guidelines

- Keep PRs focused — one improvement per PR
- Update [CHANGELOG.md](CHANGELOG.md) with your change under `[Unreleased]`
- Run `bash -n quickstart.sh && bash -n install.sh` and confirm both pass
- Walk through at least one TESTING.md playbook to confirm the experience still works end-to-end

## 🐙 Code of Conduct

Please read our [Code of Conduct](CODE_OF_CONDUCT.md). We're building an inclusive, welcoming community! 💜
