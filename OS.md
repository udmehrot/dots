# 💻 ThinkPad T480 OS & Window Manager Configuration Blueprint

> Exhaustive system documentation, configuration blueprint, and administration reference for **Arch Linux** & **Ubuntu 26.04 LTS ("Resolute Raccoon")**, **Intel Graphics**, **Sway (Wayland)**, **Quickshell**, **SwayNC**, and the unified **Rosé Pine** desktop ecosystem on the **Lenovo ThinkPad T480** (`thinkdad`).

---

## 📋 Table of Contents
1. [Hardware Specifications & Topology](#1-hardware-specifications--topology)
2. [Operating System & Kernel Subsystem](#2-operating-system--kernel-subsystem)
   - [2.1 Distribution & Kernel Details (Arch vs. Ubuntu 26.04)](#21-distribution--kernel-details-arch-vs-ubuntu-2604)
   - [2.2 Storage & Btrfs Subvolume Layout](#22-storage--btrfs-subvolume-layout)
   - [2.3 Initramfs & Early Kernel Mode Setting (KMS)](#23-initramfs--early-kernel-mode-setting-kms)
   - [2.4 Display Manager (Ly TUI on Arch & Ubuntu)](#24-display-manager-ly-tui-on-arch--ubuntu)
3. [Graphics & Display Architecture](#3-graphics--display-architecture)
   - [3.1 Driver Stack & Hardware Video Acceleration (VA-API / Vulkan)](#31-driver-stack--hardware-video-acceleration-va-api--vulkan)
   - [3.2 Global Wayland Session Environment](#32-global-wayland-session-environment)
   - [3.3 Multi-Monitor Topology & Clamshell Management](#33-multi-monitor-topology--clamshell-management)
   - [3.4 Cisco Desk Pro Touchscreen Digitizer Calibration](#34-cisco-desk-pro-touchscreen-digitizer-calibration)
4. [Window Manager (Sway Compositor)](#4-window-manager-sway-compositor)
   - [4.1 Window Styling, Borders & Rosé Pine Theme](#41-window-styling-borders--rosé-pine-theme)
   - [4.2 Touchpad, TrackPoint & Multitouch Gestures](#42-touchpad-trackpoint--multitouch-gestures)
   - [4.3 Comprehensive Keybindings Reference](#43-comprehensive-keybindings-reference)
   - [4.4 ThinkPad Hardware Function Keys (F1–F12)](#44-thinkpad-hardware-function-keys-f1f12)
   - [4.5 Idle & Session Management (swayidle)](#45-idle--session-management-swayidle)
   - [4.6 Window Rules & Floating Container Policies](#46-window-rules--floating-container-policies)
5. [Quickshell Desktop Shell & Status Bar](#5-quickshell-desktop-shell--status-bar)
   - [5.1 Modular Architecture & File Structure](#51-modular-architecture--file-structure)
   - [5.2 Color Tokens & Theme Palette (RosePine.qml)](#52-color-tokens--theme-palette-rosepineqml)
   - [5.3 Dynamic Tree & App Icon / Glyph Resolution](#53-dynamic-tree--app-icon--glyph-resolution)
   - [5.4 Interactive Applets & Popovers Catalog](#54-interactive-applets--popovers-catalog)
   - [5.5 Bar Geometry, Typography & Wayland Focus-Grab Popover Dismissal](#55-bar-geometry-typography--wayland-focus-grab-popover-dismissal)
6. [Notification Center (SwayNC)](#6-notification-center-swaync)
   - [6.1 Daemon Architecture & Styling](#61-daemon-architecture--styling)
   - [6.2 Widget Stack & Quick Control Grid](#62-widget-stack--quick-control-grid)
7. [App Launchers & Custom Utility Scripts](#7-app-launchers--custom-utility-scripts)
   - [7.1 Helper Scripts Catalog (~/.local/bin/)](#71-helper-scripts-catalog-localbin)
   - [7.2 Random Lockscreen Wallpaper System (lockscreen + swaylock)](#72-random-lockscreen-wallpaper-system-lockscreen--swaylock)
   - [7.3 Clipboard History Daemon (cliphist-daemon)](#73-clipboard-history-daemon-cliphist-daemon)
   - [7.4 Wallpaper Transition Daemon (awww)](#74-wallpaper-transition-daemon-awww)
   - [7.5 Screenshot & Annotation Toolchain (grim + slurp + swappy)](#75-screenshot--annotation-toolchain-grim--slurp--swappy)
8. [Keyboard Remapping (keyd) & Hardware Controls](#8-keyboard-remapping-keyd--hardware-controls)
   - [8.1 evdev Kernel Remapping Configuration](#81-evdev-kernel-remapping-configuration)
   - [8.2 The CapsLock Hyper Layer Paradigm](#82-the-capslock-hyper-layer-paradigm)
9. [Audio, Bluetooth & Network Subsystems](#9-audio-bluetooth--network-subsystems)
   - [9.1 PipeWire & WirePlumber Audio Routing](#91-pipewire--wireplumber-audio-routing)
   - [9.2 NetworkManager & BlueZ Integration](#92-networkmanager--bluez-integration)
10. [Power Management & Dual Batteries](#10-power-management--dual-batteries)
    - [10.1 Power Profiles Daemon & Intel P-State](#101-power-profiles-daemon--intel-p-state)
    - [10.2 ThinkPad PowerBridge Dual Battery Architecture](#102-thinkpad-powerbridge-dual-battery-architecture)
11. [Terminals, Shell & Theming](#11-terminals-shell--theming)
    - [11.1 WezTerm Configuration (~/.wezterm.lua)](#111-wezterm-configuration-weztermlua)
    - [11.2 Foot Terminal (~/.config/foot/foot.ini)](#112-foot-terminal-configfootfootini)
    - [11.3 Zsh Environment, Zinit & Powerlevel10k](#113-zsh-environment-zinit--powerlevel10k)
    - [11.4 GTK 3 & GTK 4 Desktop Theming](#114-gtk-3--gtk-4-desktop-theming)
12. [Dotfiles & State Management (chezmoi)](#12-dotfiles--state-management-chezmoi)
    - [12.1 Tracked Files Hierarchy](#121-tracked-files-hierarchy)
    - [12.2 Daily Workflow & Synchronization](#122-daily-workflow--synchronization)
13. [Fresh Installation & Reproduction Blueprint](#13-fresh-installation--reproduction-blueprint)
    - [13.1 Arch Linux Package Installation Checklist (pacman + yay)](#131-arch-linux-package-installation-checklist-pacman--yay)
    - [13.2 Ubuntu 26.04 LTS Installation Blueprint (APT, PPAs & Builds)](#132-ubuntu-2604-lts-installation-blueprint-apt-ppas--builds)
    - [13.3 Daemon & User Services Activation](#133-daemon--user-services-activation)
    - [13.4 Font Installation & Dotfiles Deployment](#134-font-installation--dotfiles-deployment)
14. [Quick Diagnostics & System Health Checks](#14-quick-diagnostics--system-health-checks)

---

## 1. Hardware Specifications & Topology

| Subsystem | Hardware Specification | Linux Driver / Notes |
| :--- | :--- | :--- |
| **Model** | Lenovo ThinkPad T480 (Type `20L5`) | Hostname: `thinkdad`, chassis: Clamshell laptop |
| **Processor** | Intel Core i5-8350U (4 Cores / 8 Threads @ 1.70 GHz base, 3.60 GHz max boost) | Microcode: `0xf6`, CPU driver: `intel_pstate` |
| **Integrated GPU** | Intel UHD Graphics 620 (Kaby Lake-R GT2, rev 07, PCI `00:02.0`) | Driver: `i915`, Mesa: `26.2.2`, VA-API: `intel-media-driver` (iHD) |
| **Memory** | 16 GB DDR4-2400 (15 GiB accessible) | Swap: `zram0` (4.0 GB in-memory compressed RAM swap) |
| **Storage** | 512 GB NVMe SSD (`/dev/nvme0n1`) | GPT partitioned, Btrfs with `zstd:3` compression |
| **Internal Screen** | 14.0" Full HD IPS (1920×1080 @ 60.020 Hz, aspect 16:9) | Connector: `eDP-1`, vendor: LG Display (`0x0521`) |
| **External Screen** | Cisco Systems Desk Pro 27" 4K UHD (3840×2160 @ 60.000 Hz, aspect 16:9) | Connector: `DP-2`, vertical layout: positioned above laptop screen |
| **Digitizer / Touch** | Cisco Desk Pro HID Touch Device (`1446:2821`) | Mapped 1:1 to `DP-2` output |
| **Touchpad** | Synaptics TM3276-022 (`type:touchpad`, PCI `1739:0`) | Libinput clickfinger, tap-to-click, natural scroll, DWT |
| **TrackPoint** | TPPS/2 IBM TrackPoint (`2:10:TPPS/2_IBM_TrackPoint`) | Hardware middle button scrolling, pointer accel `0.2` |
| **Dual Batteries** | ThinkPad PowerBridge (`BAT0` internal 24Wh + `BAT1` external 24Wh) | Hot-swappable external pack, managed via `upowerd` |
| **Wireless NIC** | Intel Wireless-AC 8265 (802.11ac 2x2 + Bluetooth 4.2) | Kernel module: `iwlwifi`, Bluetooth driver: `btusb` |

---

## 2. Operating System & Kernel Subsystem

### 2.1 Distribution & Kernel Details (Arch vs. Ubuntu 26.04)
| Parameter | Arch Linux Setup (`thinkdad`) | Ubuntu 26.04 LTS ("Resolute") Equivalent |
| :--- | :--- | :--- |
| **Distribution** | Arch Linux (`rolling`) | Ubuntu 26.04 LTS (`resolute`) |
| **Kernel Version** | `7.2.6-arch2-1` (`x86_64`) | Linux `6.14+` / `7.x` HWE kernel |
| **Bootloader** | `systemd-boot` (`/boot` ESP) | `systemd-boot` or `GRUB 2` (`/boot/efi`) |
| **Package Manager**| `pacman` + `yay` (AUR) | `apt` + PPAs + GitHub Releases |
| **Initramfs Generator** | `mkinitcpio` (`mkinitcpio.conf`) | `initramfs-tools` (`/etc/initramfs-tools/`) |

* **Kernel Command Line** (`/proc/cmdline`):
  ```text
  root=PARTUUID=e144d8c3-6ade-4dc1-afb5-d88c72300269 zswap.enabled=0 rootflags=subvol=@ rw rootfstype=btrfs
  ```

### 2.2 Storage & Btrfs Subvolume Layout
The primary NVMe storage (`/dev/nvme0n1`) is structured with **Btrfs** subvolumes mounted with asynchronous TRIM and Zstandard level 3 compression:

| Subvolume | Mount Point | Mount Options | Purpose | Distribution |
| :--- | :--- | :--- | :--- | :--- |
| `/@` | `/` | `rw,relatime,compress=zstd:3,ssd,discard=async,space_cache=v2` | OS root filesystem | Both |
| `/@home` | `/home` | `rw,relatime,compress=zstd:3,ssd,discard=async,space_cache=v2` | User home directories | Both |
| `/@pkg` | `/var/cache/pacman/pkg` | `rw,relatime,compress=zstd:3,ssd,discard=async,space_cache=v2` | Pacman package cache | Arch Linux |
| `/@apt` | `/var/cache/apt/archives` | `rw,relatime,compress=zstd:3,ssd,discard=async,space_cache=v2` | APT archives package cache | Ubuntu 26.04 |
| `/@log` | `/var/log` | `rw,relatime,compress=zstd:3,ssd,discard=async,space_cache=v2` | System & journal logs | Both |
| `/dev/nvme0n1p1` | `/boot` (or `/boot/efi`) | `vfat,rw,relatime,fmask=0077,dmask=0077,codepage=437` | EFI System Partition (ESP) | Both |

### 2.3 Initramfs & Early Kernel Mode Setting (KMS)
Early KMS loads the `i915` Intel graphics driver into the initramfs before user-space initialization, eliminating screen flicker and resolution mode shifts:

* **Arch Linux (`/etc/mkinitcpio.conf`)**:
  ```ini
  HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)
  ```
  Regenerate via `sudo mkinitcpio -P`.

* **Ubuntu 26.04 LTS (`initramfs-tools`)**:
  Add `i915` to `/etc/initramfs-tools/modules`:
  ```ini
  # /etc/initramfs-tools/modules
  i915
  ```
  Regenerate via `sudo update-initramfs -u -k all`.

### 2.4 Display Manager (Ly TUI on Arch & Ubuntu)
* **Architecture**: Lightweight terminal-based display manager (TUI) running on virtual terminal 1 (`tty1`), cleanly handing off session DRM control to Sway without display server bloat.
* **Service Definition**:
  * Arch Linux: `ly@tty1.service` (or `ly.service`)
  * Ubuntu 26.04 LTS: Built from source via Zig/C toolchain (`make`, `sudo make install`) and enabled via `sudo systemctl enable ly.service`.
* **Configuration File**: `/etc/ly/config.ini`
* **Session Persistence**: `/etc/ly/save.txt` (persists user `ud` and the Sway Wayland session).
* Key parameters:
  ```ini
  allow_empty_password = true
  animation = none
  ```

---

## 3. Graphics & Display Architecture

### 3.1 Driver Stack & Hardware Video Acceleration (VA-API / Vulkan)
The Intel UHD 620 GPU leverages open-source userspace drivers:
* **Mesa 3D Graphics**:
  * Arch: `mesa` (Iris / Crocus OpenGL driver)
  * Ubuntu 26.04: `libgl1-mesa-dri`, `mesa-va-drivers`, `mesa-vulkan-drivers`
* **Vulkan Driver**:
  * Arch: `vulkan-intel` (Intel Anvil Vulkan driver)
  * Ubuntu 26.04: `mesa-vulkan-drivers`
* **VA-API Acceleration**:
  * Arch: `intel-media-driver` (`iHD` driver via `libva`)
  * Ubuntu 26.04: `intel-media-va-driver-non-free` (or `intel-media-va-driver`)
  * Supported Hardware Video Codecs (Decode): **H.264 (AVC)**, **H.265 (HEVC Main/Main10)**, **VP8**, **JPEG**, **MPEG-2**, **VC-1**.
  * Verify hardware acceleration via terminal:
    ```bash
    vainfo --display drm
    ```

### 3.2 Global Wayland Session Environment
Global environment parameters are loaded by `systemd --user` from `/home/ud/.config/environment.d/`:

#### `~/.config/environment.d/20-wayland.conf`
```ini
# Wayland desktop environment definition
XDG_CURRENT_DESKTOP=sway
XDG_SESSION_DESKTOP=sway
XDG_SESSION_TYPE=wayland

# Toolkit backend integration
MOZ_ENABLE_WAYLAND=1
QT_QPA_PLATFORM=wayland;xcb
QT_WAYLAND_DISABLE_WINDOWDECORATION=1
ELECTRON_OZONE_PLATFORM_HINT=auto
_JAVA_AWT_WM_NONREPARENTING=1
```

#### `~/.config/environment.d/10-defaults.conf`
```ini
SHELL=/home/ud/.local/bin/zsh
TERMINAL=wezterm
BROWSER=vivaldi
PATH=/home/ud/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

### 3.3 Multi-Monitor Topology & Clamshell Management
Configured in `/home/ud/.config/sway/config`:
```swayconfig
# Output arrangement: External 4K monitor (DP-2) directly above laptop screen (eDP-1)
output DP-2 mode 3840x2160@60Hz scale 1.0 position 0 0
output eDP-1 scale 1.0 position 0 2160

# Clamshell mode: disable laptop internal display when lid is closed
bindswitch --reload --locked lid:on output eDP-1 disable
bindswitch --reload --locked lid:off output eDP-1 enable
```

### 3.4 Cisco Desk Pro Touchscreen Digitizer Calibration
The external Cisco Desk Pro 4K monitor features an integrated USB multi-touch digitizer mapped 1:1 to `DP-2`:
```swayconfig
input "1446:2821:Cisco_Systems,_Inc._Desk_Pro_HID_Device" {
    map_to_output DP-2
}
input "type:touch" {
    map_to_output DP-2
}
```

---

## 4. Window Manager (Sway Compositor)

* **Configuration**: `/home/ud/.config/sway/config`
* **Modifier Key**: `$mod = Mod4` (Windows / Super key)
* **System Font**: `pango:IoskeleyMono Nerd Font Mono 12`

### 4.1 Window Styling, Borders & Rosé Pine Theme
```swayconfig
default_border pixel 2
default_floating_border pixel 2
gaps inner 6
gaps outer 2

# Rosé Pine client colors
# class                 border  bground text    indicator child_border
client.focused          #ebbcba #1f1d2e #e0def4 #c4a7e7   #ebbcba
client.focused_inactive #26233a #191724 #908caa #26233a   #26233a
client.unfocused        #1f1d2e #191724 #6e6a86 #1f1d2e   #1f1d2e
client.urgent           #eb6f92 #eb6f92 #191724 #eb6f92   #eb6f92
client.placeholder      #191724 #191724 #e0def4 #191724   #191724
```

### 4.2 Touchpad, TrackPoint & Multitouch Gestures
```swayconfig
# Synaptics Touchpad
input "type:touchpad" {
    dwt enabled                  # Disable-while-typing
    tap enabled                  # Tap to click
    tap_button_map lrm           # 1-finger left, 2-finger right, 3-finger middle
    click_method clickfinger     # Click with 2 fingers for right-click
    natural_scroll enabled       # Natural reverse scrolling
    middle_emulation enabled     # Left + Right simulates middle click
    accel_profile adaptive
}

# ThinkPad TrackPoint
input "2:10:TPPS/2_IBM_TrackPoint" {
    pointer_accel 0.2
    accel_profile adaptive
}

# Multitouch Gestures & Touch Tiling Drag
tiling_drag enabled
tiling_drag_threshold 10

bindgesture swipe:3:right workspace next
bindgesture swipe:3:left workspace prev
bindgesture swipe:4:right move container to workspace next, workspace next
bindgesture swipe:4:left move container to workspace prev, workspace prev
bindgesture pinch:4:outward fullscreen toggle
bindgesture pinch:4:inward floating toggle
```

### 4.3 Comprehensive Keybindings Reference

#### Applications, Launchers & System Controls
| Keybinding | Action | Command Executed |
| :--- | :--- | :--- |
| <kbd>Super</kbd> + <kbd>Return</kbd> | Launch Terminal | `wezterm` |
| <kbd>Super</kbd> + <kbd>D</kbd> | Application Launcher | `/home/ud/.local/bin/wofi --show drun` |
| <kbd>Super</kbd> + <kbd>K</kbd> | System Shortcuts Cheat Sheet | `/home/ud/.local/bin/wofi-shortcuts` |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>V</kbd> | Clipboard History Picker | `/home/ud/.local/bin/wofi-clipboard` |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>W</kbd> | Wi-Fi Manager | `/home/ud/.local/bin/wofi-wifi` |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>E</kbd> | Power & Session Menu | `/home/ud/.local/bin/wofi-power` |
| <kbd>Super</kbd> + <kbd>Escape</kbd> / <kbd>Alt</kbd>+<kbd>L</kbd> | **Lock Screen (Random Wallpaper)** | `/home/ud/.local/bin/lockscreen` |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>B</kbd> | Wallpaper Selector Menu | `/home/ud/.local/bin/wofi-wallpaper` |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>B</kbd> | Instant Random Wallpaper | `/home/ud/.local/bin/wofi-wallpaper random` |
| <kbd>Super</kbd> + <kbd>N</kbd> / <kbd>Shift</kbd>+<kbd>N</kbd> | Toggle Notification Center | `swaync-client -t -sw` |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>C</kbd> | Reload Sway Configuration | `swaymsg reload` |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>Q</kbd> | Close / Kill Focused Window | `swaymsg kill` |

#### Window Tiling & Workspace Navigation
| Keybinding | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>H</kbd> / <kbd>J</kbd> / <kbd>K</kbd> / <kbd>L</kbd> (or Arrows) | Focus Left / Down / Up / Right |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>H</kbd> / <kbd>J</kbd> / <kbd>K</kbd> / <kbd>L</kbd> | Move Focused Container Directionally |
| <kbd>Super</kbd> + <kbd>B</kbd> / <kbd>Super</kbd> + <kbd>V</kbd> | Split Container Horizontally / Vertically |
| <kbd>Super</kbd> + <kbd>S</kbd> / <kbd>W</kbd> / <kbd>E</kbd> | Stacking / Tabbed / Toggle Split Layout |
| <kbd>Super</kbd> + <kbd>F</kbd> | Toggle Fullscreen |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>Space</kbd> | Toggle Floating / Tiling Mode |
| <kbd>Super</kbd> + <kbd>Space</kbd> | Swap Focus between Tiling and Floating Containers |
| <kbd>Super</kbd> + <kbd>A</kbd> | Focus Parent Container |
| <kbd>Super</kbd> + <kbd>R</kbd> | Enter Resize Mode (<kbd>HJKL</kbd> / <kbd>Arrows</kbd>, <kbd>Esc</kbd> exits) |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>-</kbd> | Move Window to Scratchpad |
| <kbd>Super</kbd> + <kbd>-</kbd> | Cycle / Show Scratchpad Window |
| <kbd>Super</kbd> + <kbd>1</kbd> .. <kbd>0</kbd> | Switch to Workspace 1..10 |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>1</kbd> .. <kbd>0</kbd> | Move Window to Workspace 1..10 |

#### Screenshot Toolchain
| Keybinding | Action | Destination |
| :--- | :--- | :--- |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd> / <kbd>Super</kbd> + <kbd>Print</kbd> | Interactive Area Select & Annotate | Swappy Editor (Save / Copy) |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>S</kbd> | Quick Area Selection | Directly copied to Clipboard |
| <kbd>Print</kbd> / <kbd>Ctrl</kbd> + <kbd>Print</kbd> | Quick Full Screen | Directly copied to Clipboard |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>Print</kbd> | Area Selection | Saved to `~/Pictures/Screenshots/` |
| <kbd>Shift</kbd> + <kbd>Print</kbd> | Full Screen | Saved to `~/Pictures/Screenshots/` |

### 4.4 ThinkPad Hardware Function Keys (F1–F12)
* **F1** (`XF86AudioMute`): Mute audio sink (`wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle`)
* **F2 / F3** (`XF86AudioLowerVolume` / `XF86AudioRaiseVolume`): Volume -/+ 5% (capped at 150%)
* **F4** (`XF86AudioMicMute`): Mute microphone (`wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle`)
* **F5 / F6** (`XF86MonBrightnessDown` / `XF86MonBrightnessUp`): Screen brightness -/+ 5%
* **F7** (`XF86Display`): Toggle external display power
* **F8** (`XF86WLAN`): Toggle Wi-Fi radio (`rfkill toggle wifi`)
* **F9** (`XF86Tools`): Open application launcher (`wofi`)
* **F10** (`XF86Bluetooth`): Toggle Bluetooth radio (`rfkill toggle bluetooth`)
* **F11 / Fn+Space** (`XF86Keyboard` / `XF86KbdLightOnOff`): Step keyboard backlight (`brightnessctl --device='tpacpi::kbd_backlight' set +1`)
* **F12** (`XF86Favorites`): Launch WezTerm
* **Fn + 4** (`XF86Sleep`): Suspend system (`systemctl suspend`)
* **Media Keys** (`Play / Pause / Next / Prev`): Controlled via `playerctl`

### 4.5 Idle & Session Management (swayidle)
Configured in `~/.config/sway/config`:
```swayconfig
exec swayidle -w \
     timeout 300 '/home/ud/.local/bin/lockscreen' \
     timeout 600 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
     before-sleep '/home/ud/.local/bin/lockscreen'
```

### 4.6 Window Rules & Floating Container Policies
```swayconfig
for_window [app_id="floating_control"] floating enable, resize set width 760 px height 520 px, move position center
for_window [app_id="nm-connection-editor"] floating enable
for_window [app_id="pavucontrol"] floating enable, resize set width 760 px height 520 px, move position center
for_window [app_id="org.pulseaudio.pavucontrol"] floating enable, resize set width 760 px height 520 px, move position center
for_window [app_id="swappy"] floating enable, resize set width 1050 px height 720 px, move position center, border pixel 3
for_window [class="com-nuvio-app-MainKt"] inhibit_idle visible, border none
```

---

## 5. Quickshell Desktop Shell & Status Bar

**Quickshell** provides the status bar and interactive system applets using modern Qt6/QML.

### 5.1 Modular Architecture & File Structure
Directory: `/home/ud/.config/quickshell/`
```text
~/.config/quickshell/
├── shell.qml                  # Core desktop shell, top bar & popup controllers (~2400 lines)
├── RosePine.qml               # Color palette singleton and typography tokens
├── AudioService.qml           # PipeWire / WirePlumber asynchronous IPC service
├── AudioSlider.qml            # Smooth volume slider with mouse-wheel step support
├── AudioWidget.qml            # Detailed multi-channel audio popover
└── AudioWidgetStandalone.qml  # Dedicated pop-out audio control window
```

### 5.2 Color Tokens & Theme Palette (RosePine.qml)
```qml
pragma Singleton
import QtQuick

QtObject {
    // Base surface colors
    readonly property color base: "#191724"
    readonly property color surface: "#1f1d2e"
    readonly property color overlay: "#26233a"
    readonly property color muted: "#6e6a86"
    readonly property color subtle: "#908caa"
    readonly property color text: "#e0def4"

    // Accents
    readonly property color love: "#eb6f92"
    readonly property color gold: "#f6c177"
    readonly property color rose: "#ebbcba"
    readonly property color pine: "#31748f"
    readonly property color foam: "#9ccfd8"
    readonly property color iris: "#c4a7e7"

    // Highlights
    readonly property color highlightLow: "#21202e"
    readonly property color highlightMed: "#403d52"
    readonly property color highlightHigh: "#524f67"

    // Font family
    readonly property string fontMono: "IoskeleyMono Nerd Font Mono"
}
```

### 5.3 Dynamic Tree & App Icon / Glyph Resolution
Quickshell maintains real-time synchronization with the Sway compositor:
1. Spawns `swaymsg -t get_tree --raw` in the background.
2. Recursively parses the JSON container hierarchy into workspace nodes.
3. For each active container, resolves its application icon via `Quickshell.iconPath()` or falls back to custom Nerd Font glyphs:
   * `` Terminal (`wezterm`, `foot`, `kitty`)
   * `󰈹` Web Browser (`vivaldi`, `firefox`, `chromium`)
   * `󰨞` Code Editor (`code`, `nvim`)
   * `󰉋` File Manager (`thunar`, `yazi`)
   * `󱓧` Notes (`obsidian`)
   * `󰕼` Media (`mpv`, `vlc`)

### 5.4 Interactive Applets & Popovers Catalog
* **Multi-Monitor Bar Variants**: Uses Quickshell's `Variants` over connected Wayland outputs to automatically draw independent status bars on `DP-2` and `eDP-1`.
* **Audio Sinks & Stream Volume**: Asynchronous PipeWire service queries `wpctl` and `pactl` to display master volume sliders, mute buttons, and active output sink switchers.
* **Bluetooth Popover**: Scans paired and connected devices via `bluetoothctl`, offering one-click connect/disconnect buttons.
* **Wi-Fi Popover**: Queries `nmcli` for nearby access points with signal strength indicators.
* **Interactive Calendar**: Dropdown with previous/next month navigation and "Jump to Today" action.
* **Live Weather Widget**: Queries the Open-Meteo REST API using laptop geolocation to display live temperatures, conditions, and hourly forecast graphs.
* **SwayNC Notification Badge**: Listens to `swaync-client -swb` to render unread notification counts and Do Not Disturb state.
* **PowerBridge Dual Battery Indicator**: Real-time visualization of combined battery percentage, remaining charging/discharging time, and active power profiles.

### 5.5 Bar Geometry, Typography & Wayland Focus-Grab Popover Dismissal
* **Bar Geometry & Layer Shell**:
  * Status bar window `implicitHeight` set to **`40px`** with **`14px`** horizontal side padding across both `eDP-1` and `DP-2`.
  * Status bar pills feature a standardized height of **`30px`** and corner radius of **`7px`**, maintaining a symmetrical **`5px`** vertical breathing margin inside the bar.
  * System tray items are housed in **`30×30px`** pills with **`19px`** high-resolution icons.
* **Unified Typography & Glyph Sizing**:
  * Pill body text (workspaces, weather, clock date/time, volume %, Bluetooth device name, Wi-Fi SSID, battery %) standardized to **`14px`** (`IoskeleyMono Nerd Font Mono`).
  * Pill icons and status glyphs standardized to **`16px`** for immediate legibility across 1080p and 4K displays.
  * Workspace application containers sized to `19×19px` with `18px` desktop icon images and `15px` fallback Nerd Font glyphs.
  * SwayNC notification pill features an `18px` pill badge with `11px` bold unread counts and a `13px` DND indicator.
* **Outside-Click Dismissal via Wayland Focus Grab (`grabFocus`)**:
  * All interactive `PopupWindow` dropdowns (`weatherMenu`, `calMenu`, `audioMenu`, `btMenu`, `wifiMenu`) utilize `grabFocus: true` to bind to Wayland XDG popup grabbing semantics.
  * Clicking anywhere outside an active dropdown (including root desktop background, tiling window surfaces, or other bar widgets) or pressing <kbd>Escape</kbd> automatically dismisses the popover.
  * Debounced state tracking (`lastCloseTime`) on each trigger pill prevents event pass-through race conditions, ensuring clicking an open popover's trigger cleanly closes it without re-triggering an immediate open.

---

## 6. Notification Center (SwayNC)

* **Daemon**: `swaync` (SwayNotificationCenter)
* **Configuration**: `/home/ud/.config/swaync/config.json`
* **Styling**: `/home/ud/.config/swaync/style.css` (Rosé Pine CSS theme)

### 6.1 Daemon Architecture & Styling
* Slides out smoothly from the top-right edge (<kbd>Super</kbd> + <kbd>N</kbd>).
* Built on Wayland `layer-shell` (layer: `overlay`), featuring a 380px panel width and responsive layout.

### 6.2 Widget Stack & Quick Control Grid
1. **Header**: "Notifications" with "󰆴 Clear" button.
2. **Do Not Disturb (DND) Switch**: Toggles system-wide notification popups.
3. **Quick Toggle Grid**:
   * `󰤨 Wi-Fi`: Wireless radio toggle (`nmcli radio wifi on/off`).
   * `󰂯 Bluetooth`: Bluetooth radio toggle (`bluetoothctl power on/off`).
   * `󰄀 Screenshot`: Area capture tool (`grim -g "$(slurp)" - | swappy -f -`).
   * `󰒓 Settings`: Centered floating control center (`foot -a floating_control -T "Audio & Network Control" nmtui`).
4. **MPRIS Media Player**: Live album art, playback progress slider, track title, and media controls.
5. **Volume Slider**: Quick master sink volume adjustment.
6. **Backlight Slider**: Intel display brightness adjustment (`intel_backlight`).
7. **Notification Stream**: Grouped, collapsible notification cards with action buttons.

---

## 7. App Launchers & Custom Utility Scripts

* **Application Launcher**: `wofi` styled in Rosé Pine (`~/.config/wofi/config` & `style.css`).
* **Location**: `/home/ud/.local/bin/`

### 7.1 Helper Scripts Catalog (~/.local/bin/)
| Script | Invocation | Purpose |
| :--- | :--- | :--- |
| `lockscreen` | <kbd>Super</kbd> + <kbd>Escape</kbd> | Locks session with `swaylock` using a random wallpaper from `~/Pictures`. Supports `--multi` and `--dry-run`. |
| `wofi-shortcuts` | <kbd>Super</kbd> + <kbd>K</kbd> | Interactive, searchable cheat sheet of all system shortcuts and gestures. Pressing Enter executes the action. |
| `wofi-clipboard` | <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>V</kbd> | Fuzzy-search clipboard history (text & images) via `cliphist` and decode selection directly back to Wayland clipboard. |
| `wofi-wifi` | <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>W</kbd> | Graphical Wi-Fi network selector or floating `nmtui` connection manager. |
| `wofi-power` | <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>E</kbd> | Session dialog: Lock (`lockscreen`), Suspend, Logout, Reboot, or Shutdown. |
| `wofi-wallpaper` | <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>B</kbd> | Scans `~/Pictures/Walls/` and applies the chosen wallpaper via `awww` with animated transitions. |

### 7.2 Random Lockscreen Wallpaper System (lockscreen + swaylock)
* **Executable**: `/home/ud/.local/bin/lockscreen` (symlinked as `swaylock-random`).
* **Swaylock Configuration**: `/home/ud/.config/swaylock/config`:
  ```ini
  daemonize
  ignore-empty-password
  show-failed-attempts
  indicator-caps-lock
  scaling=fill
  color=191724
  font=IoskeleyMono Nerd Font Mono
  font-size=16
  indicator-radius=72
  indicator-thickness=8
  inside-color=191724cc
  inside-clear-color=191724cc
  inside-caps-lock-color=191724cc
  inside-ver-color=191724cc
  inside-wrong-color=191724cc
  ring-color=ebbcba
  ring-clear-color=f6c177
  ring-caps-lock-color=f6c177
  ring-ver-color=9ccfd8
  ring-wrong-color=eb6f92
  key-hl-color=ebbcba
  bs-hl-color=eb6f92
  text-color=e0def4
  text-clear-color=f6c177
  text-caps-lock-color=f6c177
  text-ver-color=9ccfd8
  text-wrong-color=eb6f92
  line-uses-inside
  separator-color=00000000
  ```
* **Selection Logic**: Recursively searches `~/Pictures` for `.png`, `.jpg`, `.jpeg`, and `.webp` images, explicitly excluding `~/Pictures/Screenshots/` to safeguard private captures.
* **Multi-Monitor Support**: When run with `-m` or `--multi`, queries `swaymsg -t get_outputs` and assigns an independent random wallpaper to each connected monitor (e.g. `DP-2` and `eDP-1`).
* **Triggers**:
  1. Manual shortcut: <kbd>Super</kbd> + <kbd>Escape</kbd> or <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>L</kbd>
  2. Power Menu: <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>E</kbd> $\rightarrow$ "🔒 Lock"
  3. Idle timeout: `swayidle` after 300 seconds (5 minutes) of inactivity
  4. System suspend: `swayidle` `before-sleep` trigger

### 7.3 Clipboard History Daemon (cliphist-daemon)
Executed automatically on Sway startup (`~/.local/bin/cliphist-daemon`):
```bash
#!/usr/bin/env bash
wl-paste --type text --watch cliphist store &
wl-paste --type image --watch cliphist store &
```

### 7.4 Wallpaper Transition Daemon (awww)
Managed via `awww-daemon --layer bottom`. Provides GPU-accelerated animated transitions (`wipe`, `wave`, `grow`, `fade`) when updating wallpapers.

### 7.5 Screenshot & Annotation Toolchain (grim + slurp + swappy)
* **Configuration**: `/home/ud/.config/swappy/config`
* Saves screenshots to `~/Pictures/Screenshots/` formatted as `screenshot-%Y%m%d-%H%M%S.png` with `Ioskeley Mono` typography and Rosé Pine accent annotations.

---

## 8. Keyboard Remapping (keyd) & Hardware Controls

The system utilizes `keyd` for low-level kernel evdev keyboard remapping.

### 8.1 evdev Kernel Remapping Configuration
Configured in `/etc/keyd/default.conf` (backed up in `~/.config/keyd/default.conf`):
```ini
[global]
overload_tap_timeout = 200

[keys]
repeat_rate = 25     # Repeats per second
repeat_delay = 250   # Milliseconds before first repeat

[ids]
*

[main]
capslock = layer(hyper)

[hyper]
capslock = none
a = C-A-M-a
b = C-A-M-b
c = C-A-M-c
d = C-A-M-d
# ... maps standard keys to Ctrl+Alt+Meta
```

### 8.2 The CapsLock Hyper Layer Paradigm
* **Hyper Key Concept**: Tapping or holding <kbd>CapsLock</kbd> transforms it into a `Ctrl + Alt + Super` modifier chord. This enables system-wide shortcuts that never collide with normal application bindings.

---

## 9. Audio, Bluetooth & Network Subsystems

### 9.1 PipeWire & WirePlumber Audio Routing
* **Server**: `pipewire` (1.6.8)
* **Session Manager**: `wireplumber` (1.6.8)
* **PulseAudio Emulation**: `pipewire-pulse`
* **Default Sinks**:
  1. Built-in Realtek ALC257 (`Built-in Audio Analog Stereo`)
  2. Cisco Desk Pro USB Audio (`Desk Pro Web Camera Analog Stereo`)
  3. Bluetooth Headset (e.g. `soundcore Space Q45` with LDAC / AAC codecs)

### 9.2 NetworkManager & BlueZ Integration
* **Networking**: Managed by `NetworkManager.service`.
* **Bluetooth**: Managed by `bluetooth.service`.

---

## 10. Power Management & Dual Batteries

### 10.1 Power Profiles Daemon & Intel P-State
* Managed by `power-profiles-daemon.service`.
* Active profile is set to `balanced` using the `intel_pstate` CPU driver.
* Commands:
  ```bash
  powerprofilesctl get               # View current profile
  powerprofilesctl set performance   # High performance mode
  powerprofilesctl set power-saver   # Battery conservation mode
  ```

### 10.2 ThinkPad PowerBridge Dual Battery Architecture
The ThinkPad T480 features two batteries:
* `BAT0`: Internal 24 Wh battery.
* `BAT1`: External swappable 24 Wh battery.
* The Linux kernel drains `BAT1` first so that the external battery can be hot-swapped without shutting down the laptop.

---

## 11. Terminals, Shell & Theming

### 11.1 WezTerm Configuration (~/.wezterm.lua)
* **Color Scheme**: `Rosé Pine (Gogh)`
* **Font**: `IoskeleyMono Nerd Font Mono` (size 12) with `Symbols Nerd Font Mono` and `JetBrains Mono` fallbacks.
* **Window Styling**: Borderless (`window_decorations = "NONE"`), padding `8px`, opacity `1.0`.
* **Tab Bar**: Integrated at the bottom with custom Rosé Pine tab highlights and active process name indicators.

### 11.2 Foot Terminal (~/.config/foot/foot.ini)
* Lightweight Wayland-native terminal used for sub-second launch times and floating dialogs (`floating_control`).
* Styled with Rosé Pine 16-color ANSI palette.

### 11.3 Zsh Environment, Zinit & Powerlevel10k
* **Shell**: Zsh 5.9 with **Zinit** plugin manager.
* **Prompt**: Powerlevel10k (`p10k`) instant prompt.
* **Plugins**: `zsh-syntax-highlighting`, `zsh-autosuggestions`, `zsh-completions`, `fzf-tab`, `zsh-poetry`.
* **Aliases**:
  * `ls` $\rightarrow$ `eza` (modern colorized file listing)
  * `vim` $\rightarrow$ `nvim` (Neovim)
  * `c` $\rightarrow$ `clear`

### 11.4 GTK 3 & GTK 4 Desktop Theming
Configured via `gsettings` and `~/.config/gtk-3.0/settings.ini` / `~/.config/gtk-4.0/settings.ini`:
```ini
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=Adwaita-dark
gtk-font-name=Ioskeley Mono 13
```

---

## 12. Dotfiles & State Management (chezmoi)

Dotfiles are tracked and managed using **chezmoi** in `/home/ud/.local/share/chezmoi/`.

### 12.1 Tracked Files Hierarchy
```text
~/.local/share/chezmoi/
├── OS.md
├── dot_bashrc
├── dot_bash_profile
├── dot_zshenv
├── dot_zshrc
├── dot_config/
│   ├── environment.d/
│   ├── foot/
│   ├── gtk-3.0/
│   ├── gtk-4.0/
│   ├── keyd/
│   ├── nvim/
│   ├── quickshell/
│   ├── swappy/
│   ├── sway/
│   ├── swaylock/
│   ├── swaync/
│   └── wofi/
└── dot_local/
    └── bin/
        ├── cliphist-daemon
        ├── executable_lockscreen
        ├── executable_wofi-clipboard
        ├── executable_wofi-power
        ├── executable_wofi-shortcuts
        ├── executable_wofi-wallpaper
        └── executable_wofi-wifi
```

### 12.2 Daily Workflow & Synchronization
```bash
# Check differences between live system and repository
chezmoi diff

# View status of tracked files
chezmoi status

# Add updated configuration
chezmoi add ~/OS.md
chezmoi add ~/.config/sway/config
chezmoi add ~/.config/swaylock/config
chezmoi add ~/.local/bin/lockscreen

# Apply changes from repository to home directory
chezmoi apply

# Commit and push to remote repository
cd ~/.local/share/chezmoi
git add -A
git commit -m "Update desktop configuration"
git push
```

---

## 13. Fresh Installation & Reproduction Blueprint

### 13.1 Arch Linux Package Installation Checklist (pacman + yay)
```bash
# 1. Base system, Wayland, graphics, audio, and tools
sudo pacman -Syu --needed \
    sway swaylock swayidle xorg-xwayland \
    polkit polkit-gnome \
    xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
    mesa vulkan-intel intel-media-driver libva-utils \
    pipewire pipewire-pulse pipewire-alsa wireplumber pavucontrol playerctl brightnessctl \
    networkmanager bluez bluez-utils upower power-profiles-daemon \
    grim slurp swappy wl-clipboard cliphist \
    wezterm foot zsh git curl jq chezmoi keyd ly \
    gtk3 gtk4 gnome-themes-extra gsettings-desktop-schemas

# 2. Install yay AUR helper
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay && makepkg -si && cd ~

# 3. AUR packages
yay -S --needed quickshell sway-notification-center wofi awww eza
```

### 13.2 Ubuntu 26.04 LTS Installation Blueprint (APT, PPAs & Builds)

#### Step 1: Base System, Wayland, Graphics, Audio & Toolchain (APT)
```bash
sudo apt update && sudo apt install -y \
    sway swaylock swayidle xwayland \
    policykit-1-gnome xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
    libgl1-mesa-dri mesa-vulkan-drivers intel-media-va-driver-non-free vainfo libva-wayland2 \
    pipewire pipewire-pulse pipewire-alsa wireplumber pavucontrol playerctl brightnessctl \
    network-manager bluez bluez-tools upower power-profiles-daemon \
    grim slurp swappy wl-clipboard \
    foot zsh git curl jq chezmoi keyd \
    libgtk-3-dev libgtk-4-dev gnome-themes-extra gsettings-desktop-schemas \
    build-essential cmake ninja-build pkg-config libpam0g-dev
```

#### Step 2: Third-Party Repositories (WezTerm, SwayNC, eza)
```bash
# 1. WezTerm Terminal
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /etc/apt/keyrings/wezterm-fury.gpg
echo 'deb [signed-by=/etc/apt/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list

# 2. SwayNC Notification Center
sudo add-apt-repository -y ppa:erik-reider/sway-notification-center

# 3. eza (Modern ls)
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --yes --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list

# Update & Install
sudo apt update && sudo apt install -y wezterm sway-notification-center eza wofi
```

#### Step 3: Quickshell Desktop Shell on Ubuntu 26.04
Quickshell is built against modern Qt6 and Wayland libraries:
```bash
# Install Qt6 and Wayland build headers
sudo apt install -y \
    qt6-base-dev qt6-declarative-dev qt6-wayland-dev \
    libwayland-dev libpipewire-0.3-dev libwireplumber-0.5-dev \
    libpam0g-dev libpolkit-gobject-1-dev libxcb-cursor-dev

# Clone and compile Quickshell
git clone https://github.com/outfoxxed/quickshell.git /tmp/quickshell
cd /tmp/quickshell
cmake -B build -GNinja -DCMAKE_BUILD_TYPE=Release
ninja -C build
sudo ninja -C build install
```

#### Step 4: Auxiliary Utilities (cliphist, awww, ly TUI)
```bash
# 1. cliphist (Wayland clipboard history manager)
mkdir -p ~/.local/bin
curl -sL https://github.com/sentriz/cliphist/releases/latest/download/v0.5.0-linux-amd64 -o ~/.local/bin/cliphist
chmod +x ~/.local/bin/cliphist

# 2. awww (Wallpaper animation daemon)
# Installed via cargo or downloaded prebuilt binary
cargo install awww || curl -sL https://github.com/Aetf/awww/releases/latest/download/awww-x86_64-unknown-linux-gnu.tar.gz | tar -xz -C ~/.local/bin

# 3. Ly TUI Display Manager
sudo apt install -y build-essential libpam0g-dev libxcb-xkb-dev
git clone --recurse-submodules https://github.com/fairyglade/ly /tmp/ly
cd /tmp/ly && make && sudo make install
sudo systemctl enable ly.service
```

### 13.3 Daemon & User Services Activation
```bash
# System services (both Arch & Ubuntu)
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth
sudo systemctl enable --now power-profiles-daemon
sudo systemctl enable --now keyd

# Display manager service:
# Arch:   sudo systemctl enable ly@tty1.service
# Ubuntu: sudo systemctl enable ly.service

# User audio services (both Arch & Ubuntu)
systemctl --user enable --now pipewire pipewire-pulse wireplumber
```

### 13.4 Font Installation & Dotfiles Deployment
```bash
# 1. Install Ioskeley Mono fonts
mkdir -p ~/.local/share/fonts
fc-cache -fv

# 2. Deploy dotfiles with chezmoi
chezmoi init <your-dotfiles-repo-url>
chezmoi apply

# 3. Ensure scripts are executable
chmod +x ~/.local/bin/*
```

---

## 14. Quick Diagnostics & System Health Checks

| Subsystem | Diagnostic Command (Arch & Ubuntu) | Expected Output |
| :--- | :--- | :--- |
| **Kernel & OS** | `uname -r && uptime` | `7.2.x-arch...` or `6.14.x...-generic` with active uptime |
| **Btrfs Health** | `sudo btrfs filesystem show` | Label none, active subvolumes mounted |
| **VA-API Video Accel** | `vainfo --display drm` | `Intel iHD driver`, `VAProfileH264...` |
| **Vulkan Support** | `vulkaninfo --summary` | `Intel(R) UHD Graphics 620 (KBL GT2)` |
| **Sway Displays** | `swaymsg -t get_outputs` | `eDP-1` and `DP-2` configured with correct resolutions |
| **Input Devices** | `swaymsg -t get_inputs` | Touchpad, TrackPoint, Cisco Touch identified |
| **Quickshell Process** | `pgrep -x quickshell` | Process ID returned (daemon active) |
| **Lockscreen Dry-Run** | `lockscreen --dry-run` | Prints selected random wallpaper command |
| **Audio Routing** | `wpctl status` | PipeWire client list, default sink marked with `*` |
| **Dual Batteries** | `upower -i /org/freedesktop/UPower/devices/battery_BAT0` | State, percentage, and health reported |
| **keyd Remapper** | `sudo systemctl status keyd` | `active (running)`, CapsLock acting as Hyper |
| **Package Validation** | `dpkg -l \| grep -E "(sway\|pipewire\|quickshell)"` | Ubuntu: installed packages matching blueprint |
