# 🔒 Security Policy

## 🛡️ Supported Versions

| Version | Supported |
|---------|-----------|
| 1.0.x   | ✅ Yes     |

## 🚨 Reporting a Vulnerability

We take security seriously! 🐙 If you discover a security vulnerability in this project, **please report it responsibly**.

### How to Report

1. **DO NOT** open a public GitHub issue for security vulnerabilities
2. Instead, email us at: **security@dubsopenhub.com**
3. Or use [GitHub's private vulnerability reporting](https://github.com/DUBSOpenHub/copilot-first-light/security/advisories/new)

### What to Include

Please provide as much of the following as possible:

- 📝 Description of the vulnerability
- 🔄 Steps to reproduce
- 💥 Potential impact
- 💡 Suggested fix (if you have one)

### What to Expect

- ⏱️ **Acknowledgment** within 48 hours
- 🔍 **Assessment** within 1 week
- 🛠️ **Fix or mitigation** as quickly as possible
- 🎉 **Credit** in the release notes (unless you prefer anonymity)

## 🔐 Security Features

This repository has the following GitHub security features configured:

| Feature | Status | Notes |
|---------|--------|-------|
| ✅ Dependabot Alerts | Enabled | Monitors dependencies for known vulnerabilities |
| ✅ Dependabot Security Updates | Enabled | Auto-creates PRs to fix vulnerable dependencies |
| 🔒 Secret Scanning | Available when public | Detects accidentally committed secrets |
| 🔒 Secret Scanning Push Protection | Available when public | Blocks pushes containing secrets |
| 🔒 Code Scanning (CodeQL) | Available when public | Static analysis for security bugs |

> 💡 **Note:** Secret scanning, push protection, and CodeQL code scanning are automatically enabled when this repository is made public. For private repos, these features require [GitHub Advanced Security](https://docs.github.com/en/get-started/learning-about-github/about-github-advanced-security).

## 🔏 Privacy & Data Practices

This project's scripts are designed with user safety in mind:

- 🚫 **No PII collected** — `quickstart.sh` and `install.sh` do not transmit or store any personally identifiable information
- 🔑 **No credentials stored** — the scripts never ask for or save passwords, tokens, or API keys
- 📦 **Official sources only** — all installations are fetched from official GitHub sources (`github.com`, `raw.githubusercontent.com`)
- 🏠 **Local state only** — the `~/.first-light-state` file stays on your machine and is never uploaded anywhere

## 📋 Best Practices

Since this project ships shell scripts and Copilot CLI skill instructions, the primary security considerations are:

- 🔑 **No secrets in skill or agent files** — `SKILL.md` and `agent.md` should never contain API keys, tokens, or credentials
- 📜 **Safe shell scripts** — `quickstart.sh` and `install.sh` should never pipe directly from the internet to `bash` without user confirmation
- 🔍 **Dependency awareness** — if dependencies are added in the future, keep them updated via Dependabot
- 🧪 **Validate bash changes** — all shell script changes must pass `bash -n` syntax checking

## 📄 License

This project is licensed under the [MIT License](LICENSE).
