# claude-paste

A tiny WSL2/Ubuntu helper that pulls any image on the Windows clipboard straight into your current project directory, so you can hand it to the [Claude Code](https://docs.claude.com/en/docs/claude-code) CLI without leaving your session.

Works with anything that puts an image on the clipboard: `Win+Shift+S`, Snipping Tool, ShareX, Greenshot, Lightshot, `PrtScn`, "Copy image" from a browser — if Windows sees an image in the clipboard, `grab-shot` can save it.

## Why this exists

If you run Claude Code inside WSL2/Ubuntu on Windows, there's no way to paste a screenshot directly into the CLI — the terminal can't receive clipboard images the way the desktop app can. The usual workaround is tedious:

1. Capture the image (Snipping Tool, `Win+Shift+S`, ShareX, whatever).
2. Save it to disk somewhere on the Windows side.
3. Navigate into your project's filesystem on the WSL side.
4. Move or copy the file in.
5. Tell Claude the path.

Every step is friction, and you end up doing it dozens of times a day. `claude-paste` collapses the whole dance into one command you can run **inside your existing Claude Code session**:

```
! grab-shot login-bug
```

That's it. Capture → type one line → tell Claude to look at `.info/login-bug.png`.

## How it works

`grab-shot` is a ~40-line bash script that:

1. Calls `powershell.exe` from WSL (WSL2 has Windows interop built in)
2. Uses `System.Windows.Forms.Clipboard::GetImage()` to pull the image off the Windows clipboard
3. Saves it into `.info/` (or any directory you pick) in your current working directory, using `wslpath` to translate the Linux path to a Windows path PowerShell can write to

No daemons, no watchers, no background processes. Just a bridge you call on demand.

## Install

```bash
./install.sh                    # installs grab-shot to ~/.local/bin (default dir: .info)
./install.sh gs                 # full install PLUS a short 'gs' symlink
./install.sh -D notes gs        # bake a custom default directory ('notes' instead of '.info')
./install.sh -f -D notes gs     # force overwrite (use to upgrade or change the baked default)
```

`install.sh` is idempotent — safe to re-run. Without `-f` it skips files that already exist. It also:

- Verifies `powershell.exe` and `wslpath` are available (WSL2 sanity check)
- Creates `~/.local/bin` if missing
- Warns if `~/.local/bin` is not on your `PATH` and tells you how to fix it

## Usage

1. Get an image on the Windows clipboard by whatever means you prefer — `Win+Shift+S`, Snipping Tool, ShareX, "Copy image" from a browser, etc.
2. In Claude Code, run it inline with `!`:

```
! grab-shot                 # → .info/screenshot_YYYYMMDD_HHMMSS.png
! grab-shot login-bug       # → .info/login-bug.png
! grab-shot notes/scratch   # → notes/scratch.png   (dir + name from one path)
```

3. Tell Claude to look at the saved file: _"check `.info/login-bug.png`"_

`.info/` is created automatically if it doesn't exist. Drop `.info/` into your `.gitignore` if you don't want screenshots committed.

## Specifying a different directory

`.info` is the out-of-the-box default, but you can save somewhere else two ways:

**Per-call** — pass a path with a `/` in it and the leading part is treated as the directory:

```
! grab-shot notes/scratch         # → notes/scratch.png
! grab-shot docs/bugs/login       # → docs/bugs/login.png
! grab-shot ./throwaway           # → ./throwaway.png  (current dir)
```

Any intermediate directories are created automatically.

**Per-machine (change the default)** — use `-D` to rewrite the baked-in default. You can do this at install time:

```bash
./install.sh -f -D notes gs       # install + set default to 'notes' + 'gs' symlink
```

…or any time afterward, directly on the installed script:

```bash
grab-shot -D notes                # set this machine's default to 'notes'
grab-shot -D .screenshots         # or back to something else
```

The installer just delegates to `grab-shot -D` under the hood, so both paths update the same line in `~/.local/bin/grab-shot`. Any future call with no path (or a path with no `/`) will use the new default.

## Short names: symlink vs alias

**Use a symlink, not a bash alias.** This is the non-obvious trap that trips people up.

Claude Code's `!` prefix runs commands in a **non-interactive** bash shell, and bash does not expand aliases in non-interactive shells by default. So if you add `alias gs='grab-shot'` to your `.bashrc`, typing `! gs` in Claude Code will fail with "command not found". The `shopt -s expand_aliases` + `BASH_ENV` workaround technically works but is fragile and surprising.

Symlinks live on the filesystem and work regardless of how the shell is invoked. Create one via the installer:

```bash
./install.sh gs           # ! gs  ← now works in Claude Code
```

Or manually any time:

```bash
ln -s ~/.local/bin/grab-shot ~/.local/bin/gs
```

Pick any short name you like (`gs`, `shot`, `pic`, `clip`, …).

## Requirements

- WSL2 (not WSL1) — needs `powershell.exe` interop
- Ubuntu or any WSL2 distro with bash
- `~/.local/bin` on your `PATH`

## Uninstall

```bash
rm ~/.local/bin/grab-shot
rm ~/.local/bin/gs        # if you created a symlink
```

## License

MIT — see [LICENSE](LICENSE).
