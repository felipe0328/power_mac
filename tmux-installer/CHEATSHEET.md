# 🪟 Tmux cheatsheet

Keep terminal work alive, organize it into tabs and splits, and return to it
later—even after closing the terminal.

**Jump to:** [60-second start](#-60-second-start) ·
[sessions](#-sessions--keep-work-running) ·
[windows](#-windows--terminal-tabs) ·
[panes](#-panes--terminal-splits) ·
[copying](#-scroll-search-and-copy) ·
[recovery](#-save-and-restore-workspaces) ·
[plugins](#-plugins-at-a-glance) ·
[troubleshooting](#-quick-fixes)

---

## 🧠 The mental model

Tmux organizes terminals in three levels:

```text
tmux server
└── session: work                 ← a persistent workspace
    ├── window 1: editor          ← like a terminal tab
    │   ├── pane 1: nvim          ← a terminal split
    │   └── pane 2: tests
    └── window 2: logs
```

| Level | Think of it as | Useful for |
| --- | --- | --- |
| **Session** | Workspace | One project or context |
| **Window** | Tab | One task inside the project |
| **Pane** | Split | Commands you need to see together |

Detaching closes the view, not the work. Programs inside the session continue
running until you close them, kill the session, or stop the tmux server.

## 🚦 Know your prefix

Most tmux shortcuts begin with a **prefix**. Press and release the prefix, then
press the shortcut key.

| Installed style | Prefix | Status bar | Palette |
| --- | :---: | :---: | --- |
| 🟣 `bottom` | `Ctrl+a` | Bottom | Purple |
| 🟢 `top` | `Ctrl+b` | Top | Green |

### How to read shortcuts

| This guide shows | What you do |
| --- | --- |
| `prefix` → `c` | Press the prefix, release it, then press `c` |
| `prefix` → `Ctrl+s` | Press the prefix, release it, then press `Ctrl+s` together |
| `Ctrl+a` | Hold `Ctrl` while pressing `a` |

For example, creating a window means `Ctrl+a` → `c` with the bottom style, or
`Ctrl+b` → `c` with the top style.

> **Remember:** `prefix` means your installed prefix throughout this guide.
> Press it twice to send the prefix key to a program—or another tmux session—
> running inside tmux.

## ⚡ 60-second start

This is the complete everyday loop:

| Step | Do this | Result |
| :---: | --- | --- |
| 1 | Run `tn work` | Start a named session |
| 2 | Press `prefix` → `\|` | Add a side-by-side pane |
| 3 | Press `prefix` → `c` | Add a window |
| 4 | Press `prefix` → `d` | Detach; work keeps running |
| 5 | Run `ta work` | Return to it later |

```text
start ──▶ work ──▶ detach ──▶ close terminal ──▶ attach ──▶ keep working
 tn       panes      prefix d                         ta
```

> **Lost?** Press `prefix` → `?` to browse every active tmux key binding.
> Press `q` to close the list.

## 🧳 Sessions — keep work running

### From your shell

This repository includes short aliases for the commands used most often:

| Goal | Short command | Full command |
| --- | --- | --- |
| Create and enter a session | `tn work` | `tmux new-session -s work` |
| List sessions | `tl` | `tmux list-sessions` |
| Attach to a session | `ta work` | `tmux attach -t work` |
| Stop one session ⚠️ | — | `tmux kill-session -t work` |
| Stop every session ⚠️ | — | `tmux kill-server` |

Commands marked ⚠️ stop the programs running inside the affected session or
server. Detach instead if you want the work to keep running.

### From inside tmux

| Keys | Action |
| --- | --- |
| `prefix` → `d` | Detach and leave everything running |
| `prefix` → `s` | Open the session chooser |
| `prefix` → `$` | Rename the current session |

## 🗂️ Windows — terminal tabs

| Keys | Action |
| --- | --- |
| `prefix` → `c` | Create a window in the current directory |
| `prefix` → `n` | Go to the next window |
| `prefix` → `p` | Go to the previous window |
| `prefix` → `1…9` | Jump to a numbered window |
| `prefix` → `w` | Open the window and session chooser |
| `prefix` → `,` | Rename the current window |
| `prefix` → `&` | Close the current window after confirmation ⚠️ |

Windows and panes start at `1`. Window numbers close their gaps automatically
when a window is removed.

## 🧩 Panes — terminal splits

```text
prefix → |                         prefix → -
┌────────────┬────────────┐        ┌─────────────────────────┐
│            │            │        │                         │
│    left    │   right    │        ├─────────────────────────┤
│            │            │        │                         │
└────────────┴────────────┘        └─────────────────────────┘
   side-by-side panes                    stacked panes
```

| Keys | Action |
| --- | --- |
| `prefix` → `\|` | Split left/right in the current directory |
| `prefix` → `-` | Split top/bottom in the current directory |
| `prefix` → `Arrow` | Move to the pane in that direction |
| `prefix` → `o` | Cycle through panes |
| `prefix` → `q` | Show pane numbers; press a number to jump |
| `prefix` → `z` | Zoom or unzoom the active pane |
| `prefix` → `x` | Close the active pane after confirmation ⚠️ |

### Mouse controls

| Gesture | Action |
| --- | --- |
| Click a pane | Focus it |
| Drag a pane border | Resize it |
| Scroll | Browse pane history |
| Drag across text | Select and copy it to the macOS clipboard |

## 📋 Scroll, search, and copy

The configuration uses familiar vi-style movement in copy mode.

```text
prefix → [  ──▶  move  ──▶  Space  ──▶  select  ──▶  y
 enter copy mode            begin selection          copy + exit
```

| Keys | Action |
| --- | --- |
| `prefix` → `[` | Enter copy mode and browse scrollback |
| `Arrow` or vi movement keys | Move through history |
| `Space` | Begin selecting text |
| `y` | Copy the selection to the macOS clipboard and exit |
| `Y` | Copy the selection, exit, and paste it at the prompt |
| `q` | Leave copy mode without copying |

`tmux-yank` also adds two shortcuts outside copy mode:

| Keys | Copies |
| --- | --- |
| `prefix` → `y` | Text from the current shell command line |
| `prefix` → `Y` | The active pane's working directory |

## 💾 Save and restore workspaces

Two plugins work together to preserve the shape of your workspace:

```text
tmux-continuum                    tmux-resurrect
automatic timer ── every 15 min ──▶ saved snapshot ──▶ restored at startup
```

| Keys or event | Action |
| --- | --- |
| `prefix` → `Ctrl+s` | Save a snapshot now |
| `prefix` → `Ctrl+r` | Restore the latest snapshot now |
| Every 15 minutes | Save automatically |
| New tmux server | Restore the latest snapshot automatically |

Snapshots include sessions, windows, pane layouts, working directories, and a
conservative set of supported programs. Pane output and scrollback are not
stored by this configuration.

> **Important:** Recovery rebuilds the workspace; it is not a backup and cannot
> recover unsaved application data or revive every arbitrary process exactly
> where it stopped.

## 📊 Read the status bar

The selected style changes its position and colors, but both layouts contain
the same information. The session name always comes first, far-left, and is
never hidden:

```text
┌──────────────────────────────────────────────────────────────────────────┐
│  work  ☺  ↕   1 editor   2 logs      CPU: 12%  RAM: 48%  Tue 10:42 AM  │
│  └session┘ └left┘ └── window list ──┘   └────── system + clock ──────┘ │
└──────────────────────────────────────────────────────────────────────────┘
```

| Area | Meaning |
| --- | --- |
| Session name | The current session, far-left. Shrinks (14 → 8 → 5 letters) as the terminal narrows or more windows are open, but is never hidden |
| `☺` | Changes color while tmux is waiting for the key after `prefix` |
| `↕` | The active pane is zoomed |
| Window list | Shows window numbers and names; the active window is highlighted. Names shrink to 4 letters once space is tight, so more windows stay visible before any get hidden |
| CPU, RAM, clock | Live system usage from `tmux-cpu` and the date/time, refreshed every 5 seconds. These drop first — RAM/CPU, then the date, then the clock itself — so the window list always keeps its room |

The bar is responsive: it reacts to both the terminal width and how many
windows are open, so tabs are never sacrificed for the sake of showing stats.
On a very narrow terminal with many windows open, the CPU/RAM/clock area can
disappear entirely — the session name is still visible in the terminal's own
title bar in that case.

## 🔌 Plugins at a glance

The installer downloads these automatically. You do not need to start them
manually.

| Plugin | What it adds | How you use it |
| --- | --- | --- |
| [TPM](https://github.com/tmux-plugins/tpm) | Installs and updates tmux plugins | `prefix` → `I`, `U`, or `Alt+u` |
| [tmux-sensible](https://github.com/tmux-plugins/tmux-sensible) | Conservative, practical tmux defaults | Automatic; no shortcuts |
| [tmux-cpu](https://github.com/tmux-plugins/tmux-cpu) | CPU and RAM values in the status bar | Automatic; look at the status bar |
| [tmux-yank](https://github.com/tmux-plugins/tmux-yank) | macOS clipboard integration | Copy with `y`, `Y`, or the mouse |
| [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) | Manual workspace snapshots | `prefix` → `Ctrl+s` / `Ctrl+r` |
| [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) | Automatic saves and startup restore | Automatic every 15 minutes |

### Manage plugins with TPM

Use these only after changing the plugin list or when repairing an installation:

| Keys | Action |
| --- | --- |
| `prefix` → `I` | Install newly configured plugins |
| `prefix` → `U` | Update installed plugins |
| `prefix` → `Alt+u` | Remove plugins no longer configured |

Installed plugins live under `~/.tmux/plugins/`.

## 🛠️ Quick fixes

| Symptom | Try this |
| --- | --- |
| Config edits do not appear | Press `prefix` → `r` |
| Unsure which prefix is active | Run `tmux show-options -gv prefix` |
| Unsure which style is installed | Run `ls -l ~/.config/tmux/style.conf` |
| Plugin shortcut is missing | Run `~/.tmux/plugins/tpm/bin/install_plugins`, then reload |
| Need to discover a binding | Press `prefix` → `?` |
| Mouse selection behaves unexpectedly | Hold `Shift` to let WezTerm select instead of tmux |

To switch styles, run one of these from the `power_mac` repository and then
reload tmux:

```bash
./install.sh --components tmux --tmux-style bottom
./install.sh --components tmux --tmux-style top
```

## 🧷 Pocket reference

| Need | Keys |
| --- | --- |
| New window | `prefix` → `c` |
| Next / previous window | `prefix` → `n` / `p` |
| Split left/right | `prefix` → `\|` |
| Split top/bottom | `prefix` → `-` |
| Move between panes | `prefix` → `Arrow` |
| Zoom a pane | `prefix` → `z` |
| Copy text | `prefix` → `[` → select → `y` |
| Detach | `prefix` → `d` |
| Save / restore | `prefix` → `Ctrl+s` / `Ctrl+r` |
| Reload config | `prefix` → `r` |
| Show every binding | `prefix` → `?` |
