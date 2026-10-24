Objective: interactive menu to customize the info lines (show/hide, order, labels).
Branch: none (directory is not a git repository; no commits possible). Delivery: single change.
Test runner: none in repo; scripted functional checks driving the menu through stdin.

## Specs

- S1: "is it possible to make a menu where we can customize lines, order, labels, hide or show..."
  - A launch flag `--customize` opens an interactive menu listing every info line.
  - The user can show/hide a line, move it up/down, and edit its label.
- S2: Saving persists the layout to the active user config by rewriting only its `print_info()` block;
  the rest of the config is untouched, a backup is written first, and hidden lines stay as
  commented `# info "Label" name` lines. (Assumption: persistence target chosen by the parent.)
- S3: Safety: if `print_info()` contains code the menu can't represent, or is defined more than once,
  refuse without modifying the file. The new file is built in a temp file and read back (bash -n and
  sourced in a subshell); it replaces the config only if it produces the edited layout. The original
  is copied to `<config>.bak` first and the write is in place (keeps permissions and symlinks).
- S4: `--help` and `neofetch.1` document `--customize`.

## Tasks

- T1 [S1-S4] inline — layout editor, persistence, docs. Status: done (scripted stdin probes pass).
- T2 [S1-S4] delegated verify (Risk item 1: rewrites existing user config). Status: done; 1 blocker fixed
  and rechecked (S2: code after closing `}` was dropped -> now refused).

## Log

- L1 (2026-10-24): "can we add an option for customizing the display variables?" then
  "is it possible to make a menu where we can customize lines, order, labels, hide or show..."
- L2: Implemented `neofetch --customize` (LAYOUT EDITOR section in `neofetch`, help, `neofetch.1`).
  Verified on bash 3.2 with piped keystrokes: rename/move/toggle/save, refusals leave file
  byte-identical, symlink + permissions kept, `.bak` matches original, existing commands unchanged.
  Verifier blocker (code after `}` dropped) fixed: closing line must be `}` alone, else exit 1.
  Known limits: blank lines inside print_info() are not preserved; `--config <symlink>` falls back
  to the XDG config (pre-existing get_full_path behaviour).
