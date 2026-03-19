# First Light — How It Works

This is a plain-language guide to what's in this folder and how the pieces fit together.

## The Two Halves

First Light has two parts that work together:

### 1. The Quickstart (`quickstart.sh`)

This is the starting point. It's a friendly, animated script that runs in your terminal and walks you through:

- Picking what your helper does (emails, summaries, brainstorming, etc.)
- Giving it a name
- Choosing its personality
- Watching it get built — real files, right on your computer

It takes about 5 minutes. No coding required.

At the end, it saves your choices and hands you off to the Copilot CLI for the deeper experience.

### 2. The Copilot CLI Skill (`SKILL.md`)

This picks up where the quickstart left off. When you open the Copilot CLI and type "first light", the skill:

- Reads your saved choices from the quickstart
- Welcomes you back by name
- Teaches your helper YOUR writing style (by looking at a sample)
- Shows you real AI output customized to your voice
- Lets you tweak it until it feels right
- Reveals what you actually accomplished (more than you think)

## The Files

```
copilot-first-light/
├── quickstart.sh                              ← The animated bash experience
├── README.md                                  ← Landing page with instructions
├── AGENTS.md                                  ← This file
├── agents/
│   └── copilot-first-light.agent.md           ← Helper personality config
└── .github/
    └── skills/
        └── copilot-first-light/
            └── SKILL.md                       ← The deeper Copilot CLI skill
```

## What Gets Created on Your Computer

When you run the quickstart, it creates:

```
~/my-first-agent/
├── prompt.md         ← Your helper's instructions and personality
└── sample-input.txt  ← Something to try it on
```

And a state file at `~/.first-light-state` that remembers your choices.

## Running It

**First time:**
```bash
bash quickstart.sh
```

**Coming back:**
Open the Copilot CLI and type "first light" — it'll pick up where you left off.

## Changing Things

Everything is just text files. Open them in any editor:

- Want your helper to be funnier? Edit `~/my-first-agent/prompt.md`
- Want to try a different personality? Run the quickstart again
- Want to start over completely? Delete `~/my-first-agent/` and `~/.first-light-state`

That's it. No special tools needed. Just words in files.
