# YaTTi Shell

A multi-tenant, sandboxed shell environment for querying YaTTi knowledgebases via SSH. Users get an isolated terminal with YaTTi commands, conversation recording, and a curated set of Unix tools.

## How It Works

Users SSH into the server and land in a [bubblewrap](https://github.com/containers/bubblewrap) namespace sandbox. The sandbox contains only approved binaries — no `python`, `wget`, `ssh`, or other tools that could be misused. All queries and responses can be saved to conversation directories for later review or export.

## Prerequisites

Install these on the host server before setup:

| Package | Install |
|---------|---------|
| bubblewrap | `apt install bubblewrap` |
| busybox-static | `apt install busybox-static` |
| curl | `apt install curl` |
| jq | `apt install jq` |
| yatti-api | `make install` from parent directory |
| joe, nano | `apt install joe nano` (optional editors) |

## Admin Setup

```bash
cd shell/
sudo make install        # Install scripts and configs
sudo make setup          # Create group, symlinks, nftables, set bwrap setuid
sudo systemctl reload ssh
```

Verify the installation:

```bash
sudo make check
```

## User Management

### Add a User

Create the user's API key via the [YaTTi admin panel](https://yatti.id/admin/) first, then:

```bash
sudo yatti-user-add <username> <ssh-public-key> <api-key>
```

Example:

```bash
sudo yatti-user-add alice "ssh-ed25519 AAAAC3Nz... alice@laptop" "okusi_abc123..."
```

If the API key is omitted, the script prompts interactively.

### List Users

```bash
sudo yatti-user-list
```

### Remove a User

```bash
sudo yatti-user-del <username>           # Archives conversations first
sudo yatti-user-del -n <username>        # No archive, delete immediately
```

Archives are saved to `/var/backups/yatti-shell/`.

---

## User Guide

### Logging In

Connect via SSH with the key your administrator provided:

```bash
ssh <username>@<server>
```

You will see the YaTTi Shell welcome screen and a prompt:

```
0:~:general@yatti
$
```

The prompt shows: `exit_code:path:conversation@yatti`

### Querying Knowledgebases

Set a default knowledgebase for your session:

```
$ setkb seculardharma
Default KB: seculardharma
0:~:general[seculardharma]@yatti
$
```

Then query without specifying the KB each time:

```
$ query what is mindfulness?
```

Or use flags for more control:

```
$ query -q "what is mindfulness?" -m gpt-4o -k 10
$ query -K peraturan.go.id -q "apa hukum korupsi?"
```

List available knowledgebases:

```
$ kb list
```

View query history:

```
$ history
$ history 10 seculardharma
```

### Conversations

Conversations are directories that store your queries, responses, and metadata.

```
$ new indonesian-law          # Create and switch to a new conversation
$ ask what are PMA requirements?   # Query and auto-save to conversation
$ list                         # List all conversations
$ use general                  # Switch back to general
$ current                      # Show active conversation details
```

When a default KB is set, `ask` uses it automatically:

```
$ setkb peraturan.go.id
$ ask what are the tax rates for foreign companies?
```

Without a default KB, specify it as the first argument:

```
$ ask seculardharma what is dukkha?
```

Saved files in each conversation directory:

| File | Content |
|------|---------|
| `NNN-query.txt` | Your question |
| `NNN-response.txt` | Full API response (JSON) |
| `NNN-meta.json` | Timestamp, KB, model, query ID |

### Available Shell Commands

**File operations**: ls, cat, cp, mv, rm, mkdir, touch, find, chmod, stat, ln

**Text tools**: grep, head, tail, wc, less, sort, uniq, tee, tr, sed, awk, xargs

**Editors**: joe, nano, vi

**System**: df, free, top, date, bc (calculator via `?`)

**Navigation**: cd, pwd, `..` (parent), `...` (grandparent)

Pipes (`|`) and redirection (`>`, `>>`) are fully supported:

```
$ kb list | grep peraturan
$ ask what is dharma? > answer.txt
$ cat conversations/general/001-response.txt | jq '.data.response'
```

### Exporting Data

From your local machine, use SFTP to download your conversations:

```bash
sftp <username>@<server>
sftp> ls conversations
sftp> get -r conversations
```

The SFTP connection is read-only — you can download but not upload.

### Tab Completion

All commands support tab completion:

```
$ setkb <TAB>            # Lists knowledgebases
$ query -K <TAB>         # Lists knowledgebases
$ query -m <TAB>         # Lists AI models
$ use <TAB>              # Lists conversations
$ kb <TAB>               # list, get, sync
$ docs <TAB>             # user, api, technical
```

---

## Security

### Sandbox Layers

1. **SSH ForceCommand** — all connections routed through the gate script
2. **bubblewrap namespace** — PID isolation, read-only host mounts
3. **Binary allowlist** — only approved tools exist in the sandbox
4. **nftables firewall** — outbound traffic restricted to yatti.id:443
5. **Resource limits** — process count, file size, memory, CPU time
6. **SFTP read-only** — data export only, no uploads

### What Users Cannot Do

- Access the host filesystem (beyond their home directory)
- Run unapproved programs (python, ssh, wget, etc.)
- Connect to any server other than yatti.id
- See other users' processes or files
- Upload files via SFTP
- Use `configure` or `update` commands (admin-managed)

## Files

| File | Installs To | Purpose |
|------|-------------|---------|
| `yatti-shell-gate` | `/usr/local/bin/` | SSH gate — routes interactive/SFTP sessions |
| `yatti-shell-launcher` | `/usr/local/bin/` | Constructs bwrap sandbox |
| `yatti-shell-setup` | `/usr/local/sbin/` | One-time system setup |
| `yatti-user-add` | `/usr/local/sbin/` | Create shell user |
| `yatti-user-del` | `/usr/local/sbin/` | Remove shell user |
| `yatti-user-list` | `/usr/local/sbin/` | List shell users |
| `bashrc` | `/usr/local/share/yatti-shell/conf/` | In-sandbox shell environment |
| `motd` | `/usr/local/share/yatti-shell/conf/` | Welcome banner |
| `50-yatti-shell.conf` | `/etc/ssh/sshd_config.d/` | SSH configuration |
| `Makefile` | — | Install/uninstall/setup targets |
