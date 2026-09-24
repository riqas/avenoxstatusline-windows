# avenoxstatusline — Windows

A Windows-ready fork of [**avenoxai/avenoxstatusline**](https://github.com/avenoxai/avenoxstatusline),
the two-line [Claude Code](https://claude.com/claude-code) status line with an ASCII pet.

```
ʕ•ᴥ•ʔ☕  Opus 5.5 · high · think   5h 41% · 7d 63%
━━━━━───  62%  ⎇ main*
```

All credit for the idea, the pet and the stateless animation trick goes to
[Avenox](https://github.com/avenoxai). This fork only makes it run correctly on
Windows (Git Bash) and adds a one-command installer.

> 🇹🇷 **Türkçe kısa kurulum:** PowerShell'i aç, aşağıdaki tek satırı yapıştır, Claude Code'u
> yeniden başlat. jq yoksa kendisi kurar, `settings.json`'ı yedekleyip günceller.

---

## Install (Windows)

In PowerShell:

```powershell
irm https://raw.githubusercontent.com/riqas/avenoxstatusline-windows/main/install.ps1 | iex
```

Then restart Claude Code. The installer:

1. installs `jq` with winget if it can't find it,
2. downloads `statusline.sh` to `~/.claude/statusline.sh`,
3. adds the `statusLine` block to `~/.claude/settings.json` — after writing a
   backup to `settings.json.bak-statusline`.

Requirements: Windows 10/11, winget, Git for Windows (Claude Code on Windows
already needs Git Bash).

**Uninstall:** delete the `statusLine` block from `~/.claude/settings.json`
(or restore the backup).

### Manual install

```bash
curl -fsSL https://raw.githubusercontent.com/riqas/avenoxstatusline-windows/main/statusline.sh \
  -o ~/.claude/statusline.sh
```

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline.sh",
    "refreshInterval": 3
  }
}
```

The script still works on macOS and Linux exactly like upstream.

---

## What was broken on Windows

The upstream script is written for macOS/Linux. On Windows it runs, but silently
renders wrong numbers. Four fixes:

| Symptom on Windows | Cause | Fix |
|---|---|---|
| Context always shows **0%**, a stray `⑂` appears | Windows `jq.exe` prints CRLF; the `\r` sticks to every field, so numbers fail validation and empty fields look non-empty | pipe jq output through `tr -d '\r'` |
| Error text dumped into the line, cache never hits | Git Bash's `stat` is GNU: `stat -f` means *filesystem* status, exits 0 and prints a block of text instead of an mtime | try `stat -c %Y` first, BSD `stat -f %m` second |
| `⎇ 0` shown as the branch in non-git folders (also on macOS) | the 5s git cache was written tab-separated — the same IFS-whitespace collapse the README warns about, so empty fields shifted left | cache fields separated by `\x1f` (not whitespace, never collapses) |
| Context bar invisible at low usage | `░` renders near-invisible in common Windows Terminal fonts | bar drawn with `━` (filled, colored) and `─` (empty, dim) |
| `jq not found` right after installing it | Claude Code's PATH is captured at launch; winget's shim isn't always created | script also looks in `~/.claude/bin` and winget's `jqlang.jq_*` package folder |

---

## The pet is a gauge

Its mood is derived from session state, so you can read how the session is going
without reading numbers:

| State | Pet | Meaning |
|---|---|---|
| context ≥ 90% | `ʕ⊙ᴥ⊙ʔ‼` red | about to compact |
| context ≥ 75% | `ʕ•﹏•ʔ💦` yellow | start wrapping up |
| pending approvals | `ʕ•ᴥ•ʔ❗` yellow | something is waiting on you |
| effort `xhigh` / `max` | `ʕ◣_◢ʔ⚡` | the expensive gear is engaged |
| context ≥ 50% | `ʕ◔ᴥ◔ʔ` | working |
| otherwise | `ʕ•ᴥ•ʔ` | idle — blinks, and every ~10s pulls a stunt (nap, dance, table flip…) |

**Line 1:** pet, model, reasoning effort, thinking, 5-hour / 7-day rate-limit usage.
**Line 2:** context bar (green → yellow → red), context %, git branch (`*` = dirty),
worktree, project badge.

Every segment hides itself when it has nothing to say.

How the animation works without any state — frames are indexed by wall-clock
time — is explained in the [upstream README](https://github.com/avenoxai/avenoxstatusline#the-trick-animating-a-stateless-script).

---

## Configuration

| Env var | Effect |
|---|---|
| `SL_BADGE_CMD` | Any command run in the repo root; its first stdout line becomes the project badge. `prefix:value` renders the prefix dimmed. |
| `SL_NO_SERAI=1` | Disable the built-in [Serai](https://serai.run) badge. |
| `SL_TICK=<int>` | Pin the animation clock (screenshots, tests). |

## Smoke test

```bash
./demo.sh          # every mood state
./demo.sh stunts   # all 9 idle stunts, frame by frame
```

---

## License

MIT © Avenox — Windows changes © 2026 riqas, same license.
