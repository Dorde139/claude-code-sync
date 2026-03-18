# Claude Code Multi-PC Sync — Setup Instructions

When the user asks you to set this up, follow these steps. Ask questions where indicated.

## Step 1: Gather Information

Ask the user:
1. **Where are your Claude Code projects stored?** (e.g., `~/Code`, `~/Projects`, `~/Documents/Code`)
2. **Which projects should be synced?** List the folder names.

Then discover the memory directory names automatically:
```bash
ls ~/.claude/projects/
```

Match each project folder name to its encoded memory directory.

## Step 2: Create projects.conf

Edit `projects.conf` in this repo. Set `CODE_DIR` to the user's projects parent directory. Add one entry per project:

```bash
"project-name|encoded-memory-dir-name"
```

If a project has no memory directory yet, leave the encoded name empty:
```bash
"project-name|"
```

## Step 3: Generate the Encryption Key

```bash
openssl rand -hex 32 | tr -d '\r\n' > .sync-key
```

Tell the user to save this key — they'll need it on their other PC(s).

## Step 4: Run Initial Sync

```bash
bash sync-from-claude.sh
```

This populates the repo with the user's current config, encrypted .env files, settings, and memory.

## Step 5: Add the SessionStart Hook

Add this to the user's `~/.claude/settings.json` (merge with existing content if the file already exists):

```json
"hooks": {
  "SessionStart": [
    {
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "bash \"$HOME/<relative-path-to-this-repo>/auto-sync.sh\"",
          "timeout": 30
        }
      ]
    }
  ]
}
```

Replace `<relative-path-to-this-repo>` with the actual path from `$HOME` to this repo directory.

**Important:** If `~/.claude/settings.json` already has content (permissions, statusLine, etc.), merge the hooks section into the existing JSON — do not overwrite the file.

## Step 6: Push to GitHub

```bash
git add -A
git commit -m "Initial sync: config, encrypted secrets, memory"
```

Ask the user if they want to create the GitHub repo now:
```bash
gh repo create <username>/claude-dotfiles --private --source=. --push
```

## Step 7: Instructions for Other PCs

Tell the user what to do on their other PC(s):

1. Clone the repo into the same relative location
2. Create `.sync-key` with the same key
3. Run `bash sync-to-claude.sh`
4. Everything is automatic after that

## Adding New Projects Later

Just add a line to `projects.conf`. The next session start picks it up.

## Important Notes

- The `.sync-key` file is gitignored — it never gets pushed to GitHub
- `.env` files are encrypted with AES-256-CBC before being stored in the repo
- The repo MUST be private (it contains settings and encrypted secrets)
- `auto-sync.sh` runs silently — it only modifies files if the remote had changes
- On Windows/Git Bash, openssl needs Windows-style paths for the key file — the scripts handle this automatically via `cygpath`
