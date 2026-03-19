# ✨ Copilot First Light

> Build your first AI helper in 5 minutes. No coding. No experience. Just you and your ideas.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux-lightgrey)](#)

---

## ⚡ One Command. That's It.

**Never used a terminal before? No problem.** Follow these 3 steps:

**1. Open your terminal**
- 🍎 **Mac:** Press `Cmd + Space`, type **Terminal**, hit Enter
- 🐧 **Linux:** Press `Ctrl + Alt + T`

**2. Paste this line and press Enter:**
```bash
curl -fsSL https://raw.githubusercontent.com/DUBSOpenHub/copilot-first-light/main/install.sh | bash
```
*Already have Copilot CLI? No worries — the installer detects it and skips ahead.*

**3. Follow the guide**

That's it. Everything else happens automatically. ✨

---

## 🤔 What Is This?

First Light is an interactive experience that walks you through building a personal AI helper — step by step, in plain language. It installs what you need, asks a few friendly questions, and creates something real on your computer.

No coding. No jargon. Just you making choices, and watching them turn into something useful.

---

## 🎯 What Happens

The experience has two parts:

### Part 1: The Animated Guide (in your terminal)

1. 📧 **Pick what your helper does** — emails, summaries, brainstorming, or something custom
2. ✏️ **Give it a name** — whatever feels right
3. 🎯 **Choose its personality** — professional, warm, thoughtful, or punchy
4. ⚡ **Watch it get built** — real files, right on your computer
5. 🤖 **See it in action** — a live demo of your helper responding
6. 🌉 **Save it forever** — claim a free GitHub account to keep your work

### Part 2: Go Deeper (in Copilot CLI)

After the guide, you'll land in GitHub Copilot CLI. Type **`first light`** to continue:

- Teach your helper your writing style
- Try it on a real task
- Tweak it until it sounds like you
- Discover what you actually just did (it's more than you think)

---

## 📁 What You'll End Up With

A folder called `~/my-first-agent/` containing:

```
~/my-first-agent/
├── prompt.md         ← Your helper's personality and instructions
└── sample-input.txt  ← Something to try it on
```

These are just text files. Open them, change them, make them yours. That's the whole point.

---

## 🏗️ How It Works (Under the Hood)

Two scripts work together:

| File | What it does |
|------|-------------|
| `install.sh` | Bootstrap — installs gh CLI, Copilot CLI, and the First Light skill. Pretty spinners, no errors shown. |
| `quickstart.sh` | The animated experience — welcome, menus, file creation, demo, GitHub bridge, Copilot handoff. |

The install script downloads and runs the animated experience automatically. You never need to think about it.

---

## 📦 Repo Structure

```
copilot-first-light/
├── install.sh                                  ← One-command bootstrap (278 lines)
├── quickstart.sh                               ← Animated TUI experience (978 lines)
├── README.md                                   ← You are here
├── AGENTS.md                                   ← Agent guide
├── agents/
│   └── copilot-first-light.agent.md           ← Agent configuration
└── .github/skills/copilot-first-light/
    └── SKILL.md                                ← Copilot CLI skill (1,184 lines)
```

---

## ❓ FAQ

**Do I need to know how to code?**
Nope. That's the whole point.

**Is it free?**
Yes. GitHub accounts are free. Copilot CLI requires a [Copilot subscription](https://github.com/features/copilot/plans).

**What if I mess something up?**
You can't. Everything is just text files. Delete them and start over anytime.

**Can I come back later?**
Absolutely. Open your terminal, type `gh copilot`, then type `first light`. Your helper is saved on your computer.

**What does the installer actually install?**
- [GitHub CLI](https://cli.github.com/) (`gh`) — if you don't have it
- [GitHub Copilot CLI extension](https://docs.github.com/copilot) — if you don't have it
- The First Light skill — so Copilot knows how to guide you

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## 📄 License

[MIT](LICENSE) — use it, share it, remix it.

---

*Built with care for people who've never touched a terminal before.* ✨
