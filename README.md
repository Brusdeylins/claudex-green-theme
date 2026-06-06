# claudex-green-theme

An **update-proof** customizer for [claudeX](https://github.com/rse/claudex)
(Claude Code eXtended). It turns claudeX into a calm **monochrome green-on-black**
setup and gives it a richer status line — and it re-applies everything on every
launch, so it **survives `npm update -g @rse/claudex`**.

claudeX keeps its colours and status line inside its installed npm module
(`ansi-recolor.conf`, `tmux.conf`, `claudex.js`). Editing those directly works
until the next update overwrites them. `claudex-theme` instead patches them
fresh on each start, invoked right before `claudex` via a shell alias.

## Features

- **Monochrome green theme.** Every *chromatic* colour Claude emits is mapped to
  green; neutral greys / whites and `default` are left untouched, so dimmed
  "side info" stays readable instead of turning green.
- **Diff backgrounds, de-redded.** Added lines → dark green background, removed /
  other coloured backgrounds → dark grey. No red.
- **Theme-agnostic.** Rules are generated per palette index, so it works in any
  Claude Code theme (light *or* dark) — unlike the stock config, which only
  matches Claude's light theme.
- **Green tmux chrome.** Status bar, pane borders, popups and messages: active /
  current in bright green, the rest in medium green. No red/blue.
- **Mouse on by default.** The wheel always scrolls; `C-a m` toggles the tmux
  mouse off for native terminal text selection / clipboard copy, then back on.
- **Richer status line.** Replaces claudeX' hardcoded `ase statusline` format
  with one showing project · persona · task · **git branch**, model · context,
  **session/weekly usage % + reset times**, **current-month total cost** (all
  sessions), and the working directory — all rendered natively by ASE 0.9.2+,
  so no wrapper, helper scripts, or extra dependencies.

## How it works

On every run `claudex-theme`:

1. locates the installed claudeX module
   (`/usr/local/lib/node_modules/@rse/claudex`, the Homebrew path, or
   `npm root -g`);
2. **overwrites** `ansi-recolor.conf` with per-index rules (chromatic → green,
   neutrals kept, diff backgrounds handled);
3. **patches** `tmux.conf` in place (`fg=red`/`fg=blue` → green);
4. **rewrites** the `ase statusline` command claudeX hardcodes in `claudex.js`
   to our format (single command — ASE 0.9.2+ renders reset times and the
   monthly cost natively, so no wrapper or helper scripts are needed).

Every step is **idempotent** and only touches the `@rse/claudex` module — never
your own files.

> Recolor must be **on** (`claudex --recolor` / `-R`) for the pane colours to
> apply. The alias enables it.

## Requirements

- macOS (uses BSD `sed -i ''`)
- [claudeX](https://github.com/rse/claudex) with **ASE ≥ 0.9.2** (`ase` /
  `ansi-recolor`) — 0.9.2 renders the rate-limit reset times (`%D`/`%Q`) and the
  current-month cost (`%Y`) natively, which this tool's status line relies on.

## Install

```sh
./install.sh
```

This installs `claudex-theme` to `/usr/local/bin`, applies everything once, and
adds this alias to `~/.zprofile`:

```sh
alias c="claudex-theme && claudex --tmux --ase --recolor"
```

Custom prefix: `PREFIX=~/.local/bin ./install.sh`

Then open a new terminal and start a fresh session:

```sh
source ~/.zprofile
tmux kill-server   # drop old sessions still using the previous config
c
```

## Customize

Everything lives at the top of the `claudex-theme` script. Edit, then re-run
`./install.sh`.

### Colours (256-color indices)

```sh
GREEN_FG=46         # chromatic foreground -> bright green (main accent)
GREEN_FG_DIM=22     # dimmed chromatic foreground -> dark green
BG_ADD=22           # diff "added" / greenish background -> dark green
BG_MUTED=236        # diff "removed" / other coloured background -> dark grey
GREEN_BRIGHT=46     # tmux: active / current
GREEN_MED=34        # tmux: normal accents
TMUX_MOUSE=on       # tmux mouse: "on" = wheel always scrolls ("C-a m" toggles)
```

Preview the green range:

```sh
for i in $(seq 16 51); do printf '\033[48;5;%dm %3d \033[0m' $i $i; done; echo
```

### Status line

```sh
MONTH_COST_TTL=300   # ase --month-cost-ttl: seconds to cache %Y (background refresh)
STATUSLINE="ase statusline --month-cost-ttl ${MONTH_COST_TTL} -w 0 -m 2 '%p %P %T %b' '%m %c' '%S %D %W %Q %Y' '%d'"
```

A single `ase statusline` command; each quoted group is one line. Default layout:

```
⚑ project   ☯ persona   ◉ task   ⎇ branch
⚙ model: Opus 4.8   ◔ context: ██████░░░░░░ 31%
⏲ session-usage: 5.0%   ⏱ session-resets: 2hr 13m   ⏲ weekly-usage: 32.0%   ⏱ weekly-resets: 19hr 13m   ∑ month: $1102.11
▶ cwd: /path/to/project
```

Set `STATUSLINE=""` to leave claudeX' status line untouched, or reorder/drop any
placeholder. Placeholders (`ase statusline`, ASE 0.9.2+):

| code | meaning | code | meaning |
|------|---------|------|---------|
| `%p` | project | `%S` | session usage % |
| `%P` | persona | `%D` | session reset in |
| `%T` | task | `%W` | weekly usage % |
| `%b` | git branch | `%Q` | weekly reset in |
| `%m` | model | `%Y` | **current-month total cost** |
| `%c` | context bar | `%X` | session cost |
| `%e` | effort | `%H` | elapsed |
| `%t` | thinking | `%a`/`%r` | lines +/- |
| `%d` | cwd | `%g`/`%G` | git changed / untracked |
| `%u` | user | `%M` | memory |
| `%O` | output style | `%V` | version |

> `ase statusline` has no config file for the format — it is CLI-arg-driven and
> claudeX hardcodes it — which is why this tool rewrites the command string.

## Restore the original claudeX

```sh
d=/usr/local/lib/node_modules/@rse/claudex
cp "$d/ansi-recolor.conf.orig" "$d/ansi-recolor.conf"   # if a backup exists
cp "$d/tmux.conf.orig"         "$d/tmux.conf"
npm install -g @rse/claudex                              # restores claudex.js
```

Then remove the alias line from `~/.zprofile` and delete
`/usr/local/bin/claudex-theme`.

## Files

- `claudex-theme` — the customizer (canonical source; edit here)
- `install.sh` — installer + alias setup
- generated/patched at runtime inside the claudeX module: `ansi-recolor.conf`
  (regenerated), `tmux.conf` + `claudex.js` (patched in place)

## License

MIT — see [LICENSE](LICENSE). claudeX itself is © Dr. Ralf S. Engelschall,
GPL-3.0; this project only configures it and ships none of its code.
