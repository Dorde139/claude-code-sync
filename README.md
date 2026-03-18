# Claude Code Sync

Auto-sync your Claude Code configuration, secrets, and memory across multiple PCs.

## What it syncs

| Category | How |
|----------|-----|
| Global settings, keybindings, skills | Copied directly |
| Project `.env` files | **Encrypted** with AES-256-CBC |
| Project `settings.local.json` | Copied directly |
| Claude memory (MEMORY.md, feedback) | Copied directly |

Everything is stored in a **private** git repo. A SessionStart hook runs on every Claude Code session to sync automatically.

## Quick Start

### 1. Fork this repo (private)

Click **Fork** on GitHub, then set your fork to **private** in Settings.

Or clone and create your own private repo:
```bash
git clone https://github.com/Dorde139/claude-code-sync.git my-claude-dotfiles
cd my-claude-dotfiles
rm -rf .git && git init
gh repo create my-claude-dotfiles --private --source=. --push
```

### 2. Let Claude Code set it up

Open Claude Code in this repo and say:

> **Set this up for me**

Claude will read the `CLAUDE.md`, ask which projects to sync, configure everything, and run the initial sync.

### 3. Set up your other PC(s)

Clone your private fork on PC2, then:
```bash
# Create .sync-key with the same key from PC1 (shown during setup)
echo -n "your-64-char-hex-key" > .sync-key

# Apply everything
bash sync-to-claude.sh
```

Done. Every future Claude Code session syncs automatically.

## How it works

```
┌──────┐    push     ┌─────────────────────┐     pull    ┌──────┐
│ PC 1 │ ──────────> │  GitHub (private)    │ <───────── │ PC 2 │
│      │ <────────── │  claude-dotfiles     │ ──────────>│      │
└──────┘    pull     │                     │     push    └──────┘
                     │  settings.json      │
                     │  keybindings.json   │
                     │  skills/            │
                     │  *.env.enc (AES256) │
                     │  settings.local/    │
                     │  memory/            │
                     └─────────────────────┘
```

On every Claude Code session start, `auto-sync.sh` runs:

1. **Capture** local changes into the repo
2. **Commit + push** to GitHub
3. **Pull** the other PC's changes
4. **Apply** to local machine

## Files

| File | Purpose |
|------|---------|
| `projects.conf` | Registry of projects to sync (edit this) |
| `sync-from-claude.sh` | Local machine → repo |
| `sync-to-claude.sh` | Repo → local machine |
| `auto-sync.sh` | SessionStart hook (orchestrates the full cycle) |
| `CLAUDE.md` | Instructions for Claude Code to set this up |
| `.sync-key` | Encryption key (gitignored, stays local) |

## Adding a new project

Add one line to `projects.conf`:
```bash
"my-new-project|c--Users-me-Code-my-new-project"
```

Find your memory directory name with `ls ~/.claude/projects/`.

## Security

- `.env` files are encrypted with `openssl enc -aes-256-cbc -salt -pbkdf2`
- The encryption key (`.sync-key`) is gitignored — it never leaves your machines
- Your fork **must** be a private repo
- Transfer the key once between machines (copy-paste, USB, or any secure channel)
- `openssl` is pre-installed on macOS, Linux, and Git Bash for Windows

## Requirements

- Git + GitHub account
- `openssl` (pre-installed on most systems)
- Claude Code (obviously)

## Platform support

Tested on Windows (Git Bash). Works on macOS and Linux — the scripts use `cygpath` only when available and fall back to Unix paths.

## License

MIT
