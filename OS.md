# OS and home configuration guide

This is a working map for making changes to the original machine, not a reconstruction or installation script. Paths beginning with `~` refer to the current user's home directory. Configuration, packages, running processes, monitors, and versions can change; check the live system before acting.

The home directory is **not** a Git repository. The dotfiles source is a separate Git repository at `~/.local/share/chezmoi`. This document describes the original Ubuntu machine; the older README includes Arch-oriented instructions that may not apply. This file is not automatically managed by chezmoi: its source `.chezmoiignore` explicitly ignores `OS.md`.

## First: protect existing changes

- Check `git -C ~/.local/share/chezmoi status --short` and `chezmoi status` before touching managed files. At the snapshot there are uncommitted source changes, including Sway, Zsh, and environment templates, plus an untracked environment file. Do not reset or overwrite them.
- At the snapshot, `chezmoi status` reports differences involving Sway, Zsh, Neovim lock/extras files, and Noctalia settings. In particular, live Noctalia settings are `config_version = 16`, while the source template is version 14. The live desktop may have GUI-generated changes absent from the source. Inspect both sides before choosing which to preserve.
- Use `chezmoi diff` and inspect the relevant source template and live file before any apply. These commands can display personal settings; handle output accordingly. Avoid a blanket `chezmoi apply`, `chezmoi add`, Git commit, or push without checking the consequences. Applying older templates can overwrite newer live settings; adding a live file can replace templated source or lose portability. Resolve differences deliberately and use a targeted apply only after reviewing its diff.
- Desktop and system configuration can affect login, input, displays, or locking. Keep a working session or recovery path available, validate first, and get approval before privileged, disruptive, network, install, or removal operations.
- Do not copy secrets, session data, browser databases, clipboard contents, or private documents into documentation, logs, or a dotfiles repository. This inventory intentionally maps personal-data directories without examining their contents exhaustively.

## Machine and session

| Item | Observed state |
| --- | --- |
| OS | Ubuntu 26.04.1 LTS, `resolute`; Linux `7.0.0-42-generic`, x86_64 |
| Hardware | Lenovo ThinkPad X1 Carbon Gen 12. Older repository documentation refers to a ThinkPad T480; do not assume that hardware description applies to this machine. |
| Storage | `/` and home are on `/dev/mapper/ubuntu--vg-ubuntu--lv`, ext4. Do not assume the old document's Btrfs layout. |
| Login | GDM is the configured display manager; the observed session is Sway on Wayland. GNOME configuration also exists and may matter in a different session. |
| Desktop | Sway 1.12 starts Noctalia 5.4.1 and calls `kanshi`. Kanshi's config and daemon are created/started by the monitor-layout saver on the first successful save. |
| Displays | Managed by saved Kanshi profiles; the old Sway output directives remain commented in its config. Output names and attached hardware can change. |
| System services | NetworkManager, Bluetooth, keyd, power-profiles-daemon and display-manager were active when checked. User PipeWire, pipewire-pulse, WirePlumber and desktop portals were active. |

Useful read-only checks: `cat /etc/os-release`, `uname -a`, `hostnamectl`, `findmnt -T "$HOME"`, `systemctl status <service>`, and `systemctl --user status <service>`. User-service status reflects the session, not necessarily every application's startup method.

## Where to change things

Chezmoi source files use names such as `dot_`, `executable_`, and `.tmpl`; templates are rendered into the live home directory. For managed paths, review both locations and existing drift. The live path is what applications currently read; the source path is needed for durable dotfile changes. Not all home files are managed.

| Area | Live file or directory | Source / notes |
| --- | --- | --- |
| Sway | `~/.config/sway/config` | `~/.local/share/chezmoi/dot_config/sway/config.tmpl`; also includes `/etc/sway/config.d/*` |
| Noctalia | `~/.local/state/noctalia/settings.toml` | `dot_local/state/noctalia/settings.toml.tmpl`; shell also changes live settings. `~/.config/noctalia/` was empty. |
| WezTerm | `~/.wezterm.lua` | `dot_wezterm.lua` |
| Neovim | `~/.config/nvim/` | `dot_config/nvim/`; plugin installations and editor state live elsewhere |
| Zsh and Bash | `~/.zshrc`, `~/.zshenv`, `~/.p10k.zsh`, `~/.bash_profile`, `~/.bashrc`, `~/.profile` | `dot_zshrc.tmpl`, `dot_zshenv`, `dot_bash_profile`, `dot_bashrc`; `.p10k.zsh` and `.profile` were not listed by `chezmoi managed` |
| Session environment | `~/.config/environment.d/{10-defaults,20-wayland,99-local-path}.conf` | `dot_config/environment.d/`; desktop identity comes from the chosen session, not the current 20-wayland file |
| Keyboard | `/etc/keyd/default.conf` (system), `~/.config/keyd/default.conf` (home copy) | `dot_config/keyd/default.conf`; system and home copies matched when inspected, but changing the home copy alone does not update `/etc` |
| Theme and fonts | `~/.config/gtk-3.0/`, `~/.config/gtk-4.0/`, `~/.config/fontconfig/fonts.conf`, `~/.local/share/fonts/` | Corresponding `dot_config` files are managed; font files themselves are local data. Sway also sets GNOME interface settings on reload. |
| Alternative components | `~/.config/foot/`, `waybar/`, `swaync/`, `swayosd/`, `swaylock/`, `wofi/`, `swappy/`, `quickshell/` | Their configs are managed but the Sway startup lines for Waybar, SwayNC and SwayOSD are commented out; do not assume these provide the current shell. |
| Helpers | `~/.local/bin/` | Managed helpers include `wofi-shortcuts`, `lockscreen`, `nuvio`, `qs-power`, clipboard and Wofi scripts; inspect each before editing. Other binaries/symlinks here are not all managed. |
| Autostart and services | `~/.config/autostart/`, `~/.config/systemd/user/`, `/etc/systemd/` | Dropbox has an autostart desktop entry and is also started explicitly at Sway login with `dropbox start`, which does nothing if already running. System and user units are separate; inspect actual unit files and state before modifying. |
| OpenCode | `~/.config/opencode/`, `~/.opencode/bin/`, `~/.local/share/opencode/` | Config, binaries, logs/session data respectively; may contain private information. |

### Sway and Noctalia

- Sway uses Super (`Mod4`), WezTerm as `$term`, and `noctalia msg panel-toggle launcher` as `$menu`. It starts Noctalia with `exec noctalia -d` and imports the Wayland environment for systemd/D-Bus. `exec_always` also sets GTK/GNOME dark-theme and font settings, so a Sway reload can overwrite conflicting GNOME interface preferences.
- Sway sets touchpad behavior, TrackPoint identifiers, a Cisco touch-device mapping to `DP-2`, gestures, window rules, and lid-switch output enable/disable. Hardware-specific identifiers are not proof those devices are attached. Inspect `swaymsg -t get_inputs` and `swaymsg -t get_outputs` on the actual hardware before changing them.
- The focused Sway window has a neutral `#908caa` border. Its override follows the optional `~/.config/sway/noctalia` include and uses explicit Rosé Pine Main background/text colors, so it remains valid even when Noctalia's generated file is absent. Noctalia bar capsules, their configured group, floating panels, and the taskbar's active workspace border use the same neutral color. The retained Wofi style uses it for borders too; app-specific accents can still be pink.
- Key bindings include Super+Enter terminal, Super+D launcher, Super+. emoji picker, Super+K shortcuts, Super+Shift+C reload, Super+Shift+Q close window, Super+Escape lock, Alt+Tab window switcher, Super+Shift+V clipboard, Super+N notifications and Super+Shift+N control center. Super+K is reserved for shortcuts: use Super+Up to focus upward. Super+1–0 changes workspaces. Screenshot, brightness, audio, media, and other bindings are in the Sway config; many depend on Noctalia.
- Hyper (CapsLock)+Space enters Sway's app mode; F/V/O/W/N/T/C focus or launch Firefox, Vivaldi, Outlook PWA, Webex, Obsidian, WezTerm and Cursor. Escape cancels. Hyper can remain held for the app letter; Super+Space retains its focus-mode action. The helper is `~/.local/bin/sway-focus-or-launch`; Outlook depends on the local Firefox PWA desktop ID. Super+Escape locks the screen.
- Noctalia's settings contain bar layout, plugins, lockscreen widgets per output, clipboard, screenshots, theme and wallpapers. Idle is configured to lock after 300 seconds and turn outputs off after 600 seconds; lock before suspend is enabled. Screenshots are configured to copy and save under `~/Pictures/Screenshots/`; wallpapers are under `~/Pictures/Walls/`. Rosé Pine dark is selected. Enabled plugins include display, wallpaper, Obsidian, clock, emoji and VPN integrations. Check the live settings and plugin state before changes.
- The grouped taskbar prefers symbolic application icons. WezTerm's local symbolic icon is `~/.local/share/icons/hicolor/scalable/apps/org.wezfurlong.wezterm-symbolic.svg`. Firefox's local desktop entry `~/.local/share/applications/firefox_firefox.desktop` uses the themed `firefox` icon so the existing symbolic variant can be found. This entry shadows the Snap-provided desktop file and may need to be updated if the Snap's launcher changes; it is not managed by chezmoi.
- `/dir` in the Noctalia launcher is provided by the local `udmehrot/cisco-directory` plugin in `~/.local/share/noctalia/plugins/cisco-directory/`; its files are also in the chezmoi source. It opens Cisco Directory in the default browser and uses the site's search-results URL for queries. Plugin enablement is stored in live Noctalia settings, which differ from the older chezmoi template.
- `/ddg` is provided by the local `udmehrot/duckduckgo-search` plugin in `~/.local/share/noctalia/plugins/duckduckgo-search/`, also in the chezmoi source; it opens DuckDuckGo searches in the default browser.
- `/mon name` saves the current connected Sway outputs as a Kanshi profile; `/mon --replace name` explicitly updates an existing profile. Names use letters, digits, underscores and hyphens. Only one profile is allowed per connected monitor set. `~/.local/bin/kanshi-save-layout` provides the same commands in a terminal; it checks syntax with Kanshi in an isolated Wayland environment and starts or reloads Kanshi. Saved profiles live under `~/.config/kanshi/profiles/` and are not automatically tracked by chezmoi. Display identities use make/model/serial when unique, otherwise connector names, which can change. Existing Sway lid-switch bindings can still enable or disable the laptop display.
- Validate Sway with `sway -C -c ~/.config/sway/config` in a suitable session before reloading with `swaymsg reload` or Super+Shift+C. Reload is a live change, not a dry run. Test affected shortcuts, outputs and panels afterward. Be particularly careful with lock/idle changes; keep an alternate session available. Check Noctalia's installed `--help` or UI before assuming commands from the older documentation are supported.

### Terminal, shell and editor

- WezTerm uses login Zsh, Rosé Pine, font fallback order JetBrains Mono → IoskeleyMono Nerd Font Mono → Symbols Nerd Font Mono, size 12, Wayland/WebGPU, and a custom bottom tab bar. Its `CTRL|ALT|SUPER` bindings cover panes, tabs, clipboard, and other actions. The configured Yazi action requires `yazi`, which was not found on the inspected PATH.
- Zsh uses Zinit and Powerlevel10k (`~/.p10k.zsh`); plugins are stored under `~/.local/share/zinit/`. `.zshrc` includes eza/Neovim aliases, PATH additions and Podman aliases. The `upd` alias performs real APT, Snap and Flatpak updates: don't run it as a diagnostic. Login Bash can exec Zsh. Use `zsh -n ~/.zshrc` and `bash -n ~/.bashrc ~/.bash_profile` for syntax checks, then test a new shell without closing the existing one.
- Neovim is the Snap executable `/snap/bin/nvim`, configured with LazyVim/lazy.nvim. `init.lua` loads `lua/config/lazy.lua`; use `lua/config/{options,keymaps,autocmds}.lua` for local customization and `lua/plugins/` for plugin specifications. `lua/plugins/colorscheme.lua` selects Rosé Pine. `lazyvim.json` enables Copilot, several language extras and treesitter context; `lazy-lock.json` pins plugin revisions. Plugins and Mason packages are under `~/.local/share/nvim/`, and sessions, undo and other state under `~/.local/state/nvim/`. Check before any plugin install/update: it can access the network and rewrite lock/state files.
- Environment defaults declare Zsh, WezTerm and Firefox, with `~/.local/bin` prepended to the user-service PATH. `.zshenv`, `.zshrc`, and `.bash_profile` also adjust environment/PATH. Browser associations are stored in the user's MIME defaults. A GUI application's environment may differ from an interactive shell; inspect the relevant process/session rather than assuming they match.

### Keyboard and services

The active system keyd config maps CapsLock to a `hyper` layer; keys in that layer emit Ctrl+Alt+Meta chords. This is not a standalone tap-to-Hyper binding. WezTerm uses the same modifier combination. Preserve a way to recover keyboard access when changing the mapping. `systemctl status keyd` and `cmp ~/.config/keyd/default.conf /etc/keyd/default.conf` are read-only checks; installing a changed system config and reloading its service require explicit authorization and careful review.

With Fn Lock off, the ThinkPad's F10 opens Noctalia's region screenshot selector, F11 disables the laptop touchpad, and Super+F11 enables it. The system HWDB file `/etc/udev/hwdb.d/99-thinkpad-x1-keys.hwdb` maps the newer special-key scancodes to F21/F22 so keyd can forward them; the home copy and chezmoi source are under `.config/keyd/thinkpad-x1-keys.hwdb`. Sway binds the resulting raw keycodes and targets only `11311:40:SNSL0028:00_2C2F:0028_Touchpad`. System HWDB changes require updating the database and retriggering the device; applying the home dotfiles alone does not update `/etc`.

PipeWire, pipewire-pulse and WirePlumber manage the observed user audio session. Use `wpctl status` and `systemctl --user status pipewire pipewire-pulse wireplumber` to investigate. For connectivity use `systemctl status NetworkManager bluetooth`; avoid printing connection credentials. Screen sharing involves `xdg-desktop-portal`, its wlr and GTK backends, and the Sway environment import; inspect `systemctl --user status` and session logs before changing portal configuration.

LocalSend Plus uses TCP and UDP port 53317. UFW rules are specific to the original network and interface; check `sudo ufw status verbose` and configure access for the current trusted network after restoring.

For Cisco AnyConnect-compatible VPN profiles, NetworkManager uses OpenConnect. `network-manager-applet` and `network-manager-openconnect-gnome` provide a graphical authentication agent and dialog; Sway starts `nm-applet` with a duplicate-instance guard. Noctalia hides its tray icon but keeps the agent running. A local override of VPN Manager in `~/.local/share/noctalia/plugins/vpn-manager/` launches `nmcli --ask` in a terminal directly for manual connections; automatic connection behavior remains unchanged. This local copy takes precedence over the community plugin and must be reconciled manually with upstream updates. Its source is in chezmoi.

## Installed software and package provenance

This is a selected snapshot, not an exhaustive software manifest. Re-query before installing, removing or updating anything. Installed config does not prove a program is running; a command absent from the current PATH does not prove it is absent everywhere.

| Source | Observed examples |
| --- | --- |
| APT/dpkg | Sway, Noctalia, `wezterm-nightly`, foot, kanshi, keyd, NetworkManager, BlueZ, PipeWire, WirePlumber, portal backends, GDM, Vivaldi, Obsidian and Dropbox. Sway and portal-wlr package versions indicate a PPA build. |
| Snap | Firefox and Neovim, plus Ubuntu desktop/support snaps. `/snap/bin/nvim` resolves on the inspected PATH. |
| Flatpak | Flatpak is installed; `flatpak list --app` returned no applications at inspection. Runtimes may still exist. |
| Local/other | Chezmoi in `~/.local/bin`, OpenCode in `~/.opencode/bin`, Cursor Agent symlinks in `~/.local/bin`, Zinit and Neovim plugins in `~/.local/share`, Cargo and Bun directories. Dropbox, inSync and Fleet processes were observed. |

Useful read-only inventory commands:

```sh
apt list --installed                    # potentially long
apt-mark showmanual                     # manually marked APT packages
dpkg-query -W -f='${binary:Package}\t${Version}\t${db:Status-Abbrev}\n' <package>
dpkg-query -S /path/to/executable       # find owning Debian package, if any
apt-cache policy <package>              # installed/candidate versions and sources
snap list
flatpak list --app
command -v <command>
```

APT, Snap, Flatpak, language package managers, locally installed binaries and application self-updaters are distinct. Determine the actual owner and repository before changing software. Prefer targeted operations; don't remove packages solely because old desktop configs appear unused.

## Home directory map and privacy boundaries

- `Documents/` includes an Obsidian vault; `Dropbox/` is synced user data. `Downloads/`, `Desktop/`, `Pictures/`, `Music/`, `Videos/`, `Public/`, `Templates/`, `ubuntu/` and `work/` are user-content locations. Do not reorganize, clean, or publish them without permission. `Pictures/Walls/` is used by the desktop.
- `~/.config/` contains app configuration and also sensitive application profiles, notably browser and Obsidian data. `~/.local/share/` holds chezmoi, fonts, app data, plugins, and runtime installations; `~/.local/state/` holds mutable app state. `~/.cache/` is mostly caches, but do not assume every file is disposable. `~/snap/` contains per-snap data.
- `~/.ssh/`, `~/.gnupg/`, `~/.pki/`, `~/.vpn/`, keyrings, browser profiles, GitHub/Copilot auth databases, Noctalia clipboard/notification history, shell histories, cloud sync data and AI session/log directories can contain credentials or personal information. Avoid reading or transmitting their contents unless specifically required and authorized.
- Other top-level application/runtime directories include `.bun/`, `.cargo/`, `.npm/`, `.cisco/`, `.copilot/`, `.gemini/`, `.dropbox/`, `.dropbox-dist/`, `.inSync/`, `.gphoto/` and `.opencode/`. Their presence alone does not establish active use. An opaque UUID-named directory and installer log also exist; their purpose was not established, so leave them alone.
- `~/.config/webex/fontconfig.conf` prioritizes Noto Color Emoji after Inter and was verified as a workaround for multi-character emoji in Webex space names. The Webex-generated desktop entry is included in this snapshot, but updates may replace it and remove the `FONTCONFIG_FILE` override. Check its `Exec` line after updating; direct launches do not automatically use the override.

## Change checklist

1. Identify the running component, relevant live path, ownership/package source, and corresponding chezmoi source, if any. Check current status and preserve unrelated edits.
2. Read the actual settings and templates, including system includes and GUI-generated state. Agree on the intended result and scope. For system files or software changes, check whether privileges or explicit approval are needed.
3. Make the smallest consistent change; preserve templates and local state as appropriate. Do not blindly sync all files or restart the session.
4. Validate syntax or configuration with the installed version, then apply/reload only the affected component when safe. Confirm the actual behavior in the relevant session, and check logs if necessary.
5. Record what changed, what was tested, remaining drift or risks, and update this guide when paths or architecture materially change. Do not include private data.
