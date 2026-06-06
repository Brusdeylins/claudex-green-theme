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
  with one showing project · task · **git branch**, model · effort · thinking ·
  **persona**, **session/weekly quota + reset times**, and session cost · elapsed
  · context.
- **Monthly cost (optional).** Appends a `∑ month: $…` line with your total cost
  for the current month across **all** sessions, computed by
  [`ccusage`](https://github.com/ryoppippi/ccusage) and refreshed in the
  **background** (never blocks the status line).

## How it works

On every run `claudex-theme`:

1. locates the installed claudeX module
   (`/usr/local/lib/node_modules/@rse/claudex`, the Homebrew path, or
   `npm root -g`);
2. **overwrites** `ansi-recolor.conf` with per-index rules (chromatic → green,
   neutrals kept, diff backgrounds handled);
3. **patches** `tmux.conf` in place (`fg=red`/`fg=blue` → green);
4. **generates** a status-line wrapper (`claudex-statusline` plus small
   `claudex-usage.js` / `claudex-month.js` helpers) and **points claudeX'
   statusLine at it** by patching `claudex.js`. The usage line (session/weekly
   percent **and reset time**) is rendered by us because ase 0.9.0 cannot read
   Claude's numeric `resets_at` timestamp.

Every step is **idempotent** and only touches the `@rse/claudex` module — never
your own files.

> Recolor must be **on** (`claudex --recolor` / `-R`) for the pane colours to
> apply. The alias enables it.

## Requirements

- macOS (uses BSD `sed -i ''` and `stat -f`)
- [claudeX](https://github.com/rse/claudex) and its `ase` / `ansi-recolor` tools
- [`ccusage`](https://github.com/ryoppippi/ccusage) — optional, only for the
  monthly cost line: `npm i -g ccusage`

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
STATUSLINE_TOP="ase statusline -w 0 -m 2 '%p %P %T %b' '%m %c'"
STATUSLINE_BOTTOM="ase statusline -w 0 -m 2 '%d'"
SHOW_USAGE=1        # render the "session % + reset   weekly % + reset" line
SHOW_MONTHLY=1      # append "∑ month: $<sum>" (ccusage) to the END of that line
MONTHLY_TTL=300     # seconds between background ccusage refreshes
```

The wrapper renders, top to bottom: `STATUSLINE_TOP` → the usage line (with the
monthly cost appended at its end) → `STATUSLINE_BOTTOM`. The default layout:

```
⚑ project   ☯ persona   ◉ task   ⎇ branch
⚙ model: Opus 4.8   ◔ context: ██████░░░░░░ 31%
⏲ session: 5.0% (2hr 13m)   ⏲ weekly: 32.0% (19hr 13m)   ∑ month: $1102.11
▶ cwd: /path/to/project
```

Set any part to `""` to drop it, `SHOW_USAGE=0` / `SHOW_MONTHLY=0` to disable
those. The usage line is rendered by us (not ase) so the session/weekly reset
times work regardless of how the bundled `ase` formats Claude's numeric
`resets_at` timestamp.

Placeholders (`ase statusline`):

| code | meaning | code | meaning |
|------|---------|------|---------|
| `%p` | project | `%S` | session usage % |
| `%T` | task | `%D` | session reset in |
| `%b` | git branch | `%W` | weekly usage % |
| `%m` | model | `%Q` | weekly reset in |
| `%e` | effort | `%X` | session cost |
| `%t` | thinking | `%H` | elapsed |
| `%P` | persona | `%c` | context bar |
| `%u` | user | `%C` | tokens |
| `%a`/`%r` | lines +/- | `%g`/`%G` | git changed / untracked |
| `%d` | cwd | `%M` | memory |
| `%O` | output style | `%V` | version |

> `ase statusline` has **no config** for the format — it is purely CLI-arg-driven
> and claudeX hardcodes it — which is why this tool rewrites it. There is also no
> monthly cost in `ase` (`%X` is the current session only); that is what the
> `ccusage` line adds.

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
- generated at runtime inside the claudeX module: `ansi-recolor.conf`,
  `claudex-statusline`, `claudex-usage.js`, `claudex-month.js`

## License

MIT — see [LICENSE](LICENSE). claudeX itself is © Dr. Ralf S. Engelschall,
GPL-3.0; this project only configures it and ships none of its code.
