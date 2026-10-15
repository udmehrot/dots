# 🌸 Rosé Pine Sway & Noctalia Shell Setup — Arch Linux

A modern, fluid, and cohesive Wayland desktop environment powered by **Sway** and **Noctalia Shell**, fully styled with the **Rosé Pine** color palette and **Ioskeley Mono** typography.

---

## 📸 Desktop Overview

* **Window Manager**: [Sway](https://swaywm.org/) (Wayland i3-compatible compositor)
* **Desktop Shell**: [Noctalia Shell](https://noctalia.dev/) (Unified native Wayland shell layer)
  * **Status Bar**: Dual-display status bar with workspace pills, network/cpu/mem/disk system monitors, tray, and clock
  * **Control Center & Notifications**: Integrated PipeWire audio mixer, Wi-Fi networks, Bluetooth manager, media controls, and notification toasts
  * **On-Screen Display (OSD)**: Native HUD for volume, mic, brightness, keyboard backlight, caps lock, and Wi-Fi toggles
  * **Session Lockscreen**: PAM Wayland session lock (`ext-session-lock-v1`) with weather, media controls, clock, and login box
  * **App Launcher & Dmenu**: Fast GPU-accelerated application drawer and `noctalia dmenu` system shortcuts provider
  * **Clipboard Manager**: Native Wayland clipboard history (text & images) with encrypted storage
  * **Wallpaper Engine**: Integrated multi-monitor wallpaper manager with transition animations
  * **Screenshot & Annotation**: Built-in interactive region selector, markup studio, and multi-display capture
  * **Window Switcher**: Interactive 3D carousel / compact strip Alt+Tab overlay
  * **Authentication Agent**: Integrated graphical Polkit authentication agent
* **Terminal**: [Foot](https://codeberg.org/dnkl/foot) & [WezTerm](https://wezfurlong.org/wezterm/)
* **Typography**: `Ioskeley Mono` & `IoskeleyMono Nerd Font Mono`
* **Theme & Colors**: Rosé Pine Dark (`#191724` Base, `#1f1d2e` Surface, `#ebbcba` Rose, `#eb6f92` Love, `#31748f` Pine, `#9ccfd8` Foam, `#c4a7e7` Iris)

---

## 🚀 From Barebones Arch to Current State

Follow these step-by-step instructions to recreate this exact environment from a fresh, minimal Arch Linux installation.

### 1. Base System & Essential Wayland Packages

Ensure your base Arch installation is up-to-date and install the core audio, Wayland, Sway, and utility packages:

```bash
# Update system
sudo pacman -Syu

# Base Wayland, Compositor & Graphics
sudo pacman -S --needed \
    sway xorg-xwayland \
    polkit \
    xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk

# Unified Desktop Shell Layer (Noctalia), Terminals & System Monitors
sudo pacman -S --needed noctalia foot wezterm zsh bash curl git jq btop

# Audio & Media Controls
sudo pacman -S --needed \
    pipewire pipewire-pulse pipewire-alsa wireplumber \
    pavucontrol brightnessctl

# Networking & Bluetooth
sudo pacman -S --needed \
    networkmanager bluez bluez-utils

# System Daemons & Utilities
sudo pacman -S --needed \
    upower chezmoi wl-clipboard

# GTK Theming & Engines
sudo pacman -S --needed \
    gtk3 gtk4 gnome-themes-extra gsettings-desktop-schemas
```

---

### 3. Enable System Services

Enable the essential background daemons:

```bash
# Network & Bluetooth
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth

# Enable pipewire user services (runs automatically on login)
systemctl --user enable --now pipewire pipewire-pulse wireplumber
```

---

### 4. Typography (Ioskeley Fonts)

Make sure **Ioskeley Mono** and **IoskeleyMono Nerd Font** are installed in `~/.local/share/fonts/` or `/usr/share/fonts/`:

```bash
mkdir -p ~/.local/share/fonts
# Copy your Ioskeley font files into ~/.local/share/fonts/
# Update font cache:
fc-cache -fv
```

Verify the font is available:
```bash
fc-list : family | grep -i "Ioskeley"
```

---

### 5. Apply Dotfiles with Chezmoi

Initialize and apply this dotfiles repository:

```bash
# Apply dotfiles directly from your repository:
chezmoi init <your-git-repo-url>
chezmoi apply

# Ensure all scripts in ~/.local/bin are executable:
chmod +x ~/.local/bin/*
```

Make sure `~/.local/bin` is in your `PATH` (already included in `.zshrc` and `.bashrc`).

---

### 6. Wallpapers Directory

The wallpaper switcher expects wallpapers in `~/Pictures/Walls/`:

```bash
mkdir -p ~/Pictures/Walls ~/Pictures/Screenshots
# Add your favorite wallpapers (.png, .jpg, .webp) to ~/Pictures/Walls/
```

Press **<kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>B</kbd>** to open the wallpaper picker, or **<kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>B</kbd>** for random wallpaper selection.

---

### 7. Start Sway Session

Launch Sway:

```bash
sway
```

---

## 🐧 Installation Guide for Ubuntu 26.04 (LTS Base)

You can run this exact desktop setup on **Ubuntu 26.04 LTS**. Because LTS repositories can sometimes lag behind the fast-moving Wayland ecosystem, follow these steps to install the latest tools via official PPAs, modern package managers, and standalone binaries.

### 1. Add PPAs & Repositories for Latest Sway & WezTerm

```bash
sudo apt update
sudo apt install -y software-properties-common curl gpg wget

# 1. PPA for Latest Sway & Wayland components
# (Ubuntu Sway Remix project PPA or community backports)
sudo add-apt-repository -y ppa:ubuntusway-dev/stable
# Alternative: sudo add-apt-repository -y ppa:pgentili/sway

# 2. WezTerm Official APT Repository (Optional)
curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /etc/apt/keyrings/wezterm-fury.gpg
echo 'deb [signed-by=/etc/apt/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list

sudo apt update
```

---

### 2. Install Core Packages & Dependencies

Install Sway, audio, networking, hardware acceleration, and portal libraries:

```bash
sudo apt install -y \
    sway xwayland \
    foot wezterm zsh bash curl git jq btop \
    pipewire pipewire-pulse wireplumber pavucontrol playerctl brightnessctl \
    network-manager bluez bluez-tools upower power-profiles-daemon \
    grim slurp wl-clipboard \
    xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
    libgl1-mesa-dri mesa-vulkan-drivers intel-media-va-driver-non-free vainfo \
    libgtk-3-bin libgtk-4-bin gsettings-desktop-schemas libgtk-layer-shell0
```
> [!NOTE]
> Standalone daemons like `swaylock`, `swayidle`, `waybar`, `sway-notification-center`, `wofi`, `cliphist`, `awww`, and `swappy` are **not needed** on Ubuntu—Noctalia Shell provides all of these capabilities natively in a single unified binary.

---

### 3. Install Modern Tools on LTS

#### A. Chezmoi (Dotfile Manager)
```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
```

#### B. Noctalia Shell (Unified Desktop Shell Layer)
Install the latest Noctalia Shell:
```bash
# Via official installer script:
curl -fsSL https://noctalia.dev/install.sh | bash

# Or download the prebuilt release package:
# https://github.com/noctalia-dev/noctalia/releases
```
Noctalia natively provides:
* **Dual-Monitor Status Bar** (with capsule styling and system monitors)
* **Control Center & Notifications** (audio mixer, Wi-Fi, Bluetooth, DND)
* **On-Screen Display HUD** (volume, brightness, mic mute, keyboard backlight)
* **Session Lockscreen** (PAM authentication, weather, media player, login box)
* **Idle & Power Manager** (screen fade dimming, DPMS sleep, caffeine inhibitor)
* **Clipboard Manager** (persistent image & text history via `ext_data_control_manager_v1`)
* **Wallpaper Engine** (GPU transitions, multi-monitor wallpapers, interactive gallery)
* **App Launcher & Dmenu** (fast application search and `noctalia dmenu` shortcuts)
* **Screenshot & Canvas Studio** (interactive region selection, markup tools, file save)

---

### 4. Enable Services & Permissions

```bash
# Add user to hardware groups
sudo usermod -aG video,input,audio $USER

# Enable system network and bluetooth daemons
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth

# Enable PipeWire audio services for the current user
systemctl --user enable --now pipewire pipewire-pulse wireplumber
```

---

### 5. Install Ioskeley Fonts

```bash
mkdir -p ~/.local/share/fonts
# Copy Ioskeley font files into ~/.local/share/fonts/
fc-cache -fv
```

---

### 6. Apply Dotfiles

```bash
# Initialize and apply dotfiles
chezmoi init <your-git-repo-url>
chezmoi apply

# Make all helper scripts executable
chmod +x ~/.local/bin/*
```

---

### 7. Launching Sway on Ubuntu

You can select **Sway** directly from the GDM/SDDM login screen menu, or launch it from a TTY:

```bash
sway
```

---


## ⌨️ System Shortcuts Reference

All shortcuts can be searched on the fly by pressing **<kbd>Super / Cmd</kbd> + <kbd>K</kbd>**:

### 🚀 Applications & Launchers
| Shortcut | Action | Command |
| :--- | :--- | :--- |
| **<kbd>Super</kbd> + <kbd>Return</kbd>** | Launch Foot Terminal | `foot` |
| **<kbd>Super</kbd> + <kbd>D</kbd>** | Application Launcher (Noctalia) | `noctalia msg panel-toggle launcher` |
| **<kbd>Super</kbd> + <kbd>K</kbd>** | System Shortcuts & Keybinds List | `wofi-shortcuts` (via `noctalia dmenu`) |
| **<kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>V</kbd>** | Clipboard History Manager (Noctalia) | `noctalia msg panel-toggle clipboard` |
| **<kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>W</kbd>** | Wi-Fi & Network Settings (Noctalia) | `noctalia msg panel-toggle control-center network` |
| **<kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>B</kbd>** | Next Wallpaper (Noctalia) | `noctalia msg wallpaper-next` |
| **<kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>B</kbd>** | Random Wallpaper (Noctalia) | `noctalia msg wallpaper-random` |
| **<kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>E</kbd>** | Power & Session Menu (Noctalia) | `noctalia msg panel-toggle session` |
| **<kbd>Super</kbd> + <kbd>Escape</kbd>** / **<kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>L</kbd>** | Lock Screen (Noctalia Session Lock) | `noctalia msg session lock` |
| **<kbd>Super</kbd> + <kbd>N</kbd>** | Toggle Notification Center (Noctalia) | `noctalia msg panel-toggle notifications` |
| **<kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>N</kbd>** | Toggle Control Center (Noctalia) | `noctalia msg panel-toggle control-center` |
| **<kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>I</kbd>** | Toggle Caffeine (Idle Inhibitor) | `noctalia msg caffeine-toggle` |
| **<kbd>Alt</kbd> + <kbd>Tab</kbd>** | Window Switcher Carousel (Noctalia) | `noctalia msg window-switcher` |
| **<kbd>F9</kbd>** | Noctalia Desktop Settings | `noctalia msg settings-toggle` |

### 🪟 Window Management
| Shortcut | Action |
| :--- | :--- |
| **<kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>Q</kbd>** | Close / Kill Focused Window |
| **<kbd>Super</kbd> + <kbd>F</kbd>** | Toggle Fullscreen |
| **<kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>Space</kbd>** | Toggle Floating / Tiling Mode |
| **<kbd>Super</kbd> + <kbd>Space</kbd>** | Swap Focus: Tiling $\leftrightarrow$ Floating |
| **<kbd>Super</kbd> + <kbd>A</kbd>** | Focus Parent Container |
| **<kbd>Super</kbd> + <kbd>R</kbd>** | Resize Mode (<kbd>Arrows</kbd> / <kbd>HJKL</kbd>, <kbd>Esc</kbd> to exit) |
| **<kbd>Super</kbd> + <kbd>B</kbd>** / **<kbd>Super</kbd> + <kbd>V</kbd>** | Split Container Horizontally / Vertically |
| **<kbd>Super</kbd> + <kbd>S</kbd>** / **<kbd>Super</kbd> + <kbd>W</kbd>** / **<kbd>Super</kbd> + <kbd>E</kbd>** | Stacking / Tabbed / Toggle Split Layout |
| **<kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>C</kbd>** | Reload Sway Configuration |

### 📸 Screenshots (Noctalia)
| Shortcut | Action | Output |
| :--- | :--- | :--- |
| **<kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd>**<br>or **<kbd>Super</kbd> + <kbd>Print</kbd>** | Interactive Region Select $\rightarrow$ Annotation Studio | Clipboard + `~/Pictures/Screenshots/` |
| **<kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>S</kbd>**<br>or **<kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>Print</kbd>** | Quick Area Selection | Clipboard + `~/Pictures/Screenshots/` |
| **<kbd>Print</kbd>** or **<kbd>Ctrl</kbd> + <kbd>Print</kbd>** | Quick Full Screen (Focused Monitor) | Clipboard + `~/Pictures/Screenshots/` |
| **<kbd>Shift</kbd> + <kbd>Print</kbd>** | Full Screen (All Monitors) | Clipboard + `~/Pictures/Screenshots/` |

### 🎛️ Hardware & Function Keys (Noctalia OSD)
| Key | Action | Backend |
| :--- | :--- | :--- |
| **<kbd>F1</kbd>** (`XF86AudioMute`) | Mute / Unmute Audio | `noctalia msg volume-mute` |
| **<kbd>F2</kbd> / <kbd>F3</kbd>** | Volume Down / Up (-/+ 5%) | `noctalia msg volume-down / volume-up` |
| **<kbd>F4</kbd>** (`XF86AudioMicMute`) | Mute / Unmute Microphone | `noctalia msg mic-mute` |
| **<kbd>F5</kbd> / <kbd>F6</kbd>** | Screen Brightness Down / Up (-/+ 5%) | `noctalia msg brightness-down / brightness-up` |
| **<kbd>F7</kbd>** (`XF86Display`) | Toggle Display Power | `swaymsg "output * power toggle"` |
| **<kbd>F8</kbd>** (`XF86WLAN`) | Toggle Wi-Fi Radio | `rfkill toggle wifi` |
| **<kbd>F10</kbd>** (`XF86Bluetooth`) | Toggle Bluetooth Radio | `rfkill toggle bluetooth` |
| **<kbd>F11</kbd> / <kbd>Fn</kbd> + <kbd>Space</kbd>** | Step ThinkPad Keyboard Backlight | `noctalia msg keyboard-backlight-up` |
| **Media Keys** (Play/Pause/Prev/Next) | Control Media Playback | `noctalia msg media toggle/previous/next` |

### 👆 Touch & Gesture Controls (ThinkPad / External Touchscreens)
* **3-Finger Horizontal Swipe**: Switch to previous / next workspace
* **4-Finger Horizontal Swipe**: Move focused window to previous / next workspace
* **4-Finger Pinch Outward**: Fullscreen toggle
* **4-Finger Pinch Inward**: Floating toggle
* **Touch Tiling Drag**: Enabled (drag floating or tiled windows with touch)

---

## 📁 Repository Structure

```
~/.local/share/chezmoi/
├── README.md                           # This guide
├── OS.md                               # Comprehensive system configuration blueprint
├── dot_bashrc                          # Bash configuration
├── dot_bash_profile                    # Bash profile & Wayland environment
├── dot_zshenv                          # Zsh environment variables
├── dot_zshrc                           # Zsh interactive configuration
├── dot_config/
│   ├── sway/
│   │   └── config                      # Sway window manager configuration
│   ├── waybar/
│   │   ├── config.jsonc                # Waybar top bar layout & system monitors
│   │   ├── style.css                   # Waybar Rosé Pine CSS theme
│   │   └── scripts/
│   │       ├── executable_calendar_menu.py    # Compact interactive calendar popup
│   │       ├── executable_weather_menu.py     # Live weather card & 3-day forecast
│   │       ├── executable_weather.py          # wttr.in weather data provider & cache
│   │       ├── executable_notifications.py    # SwayNC unread count streaming helper
│   │       ├── executable_bluetooth_menu.py   # Standalone Bluetooth device popup
│   │       ├── executable_wifi_menu.py        # Standalone Wi-Fi network popup
│   │       └── executable_volume_menu.py      # Standalone volume & audio popup
│   ├── swaync/
│   │   ├── config.json                 # SwayNotificationCenter Control Center layout
│   │   └── style.css                   # SwayNC Rosé Pine CSS theme
│   ├── swayosd/
│   │   ├── config.toml                 # SwayOSD server thresholds & durations
│   │   └── style.css                   # SwayOSD Rosé Pine HUD theme
│   ├── wofi/
│   │   ├── config                      # Wofi general settings
│   │   └── style.css                   # Wofi Rosé Pine CSS theme
│   ├── foot/
│   │   └── foot.ini                    # Foot terminal Rosé Pine configuration
│   ├── swappy/
│   │   └── config                      # Swappy annotation defaults
│   ├── gtk-3.0/
│   │   ├── gtk.css                     # Swappy high-contrast studio theme
│   │   └── settings.ini                # GTK3 dark mode & Ioskeley font settings
│   ├── gtk-4.0/
│   │   ├── gtk.css                     # GTK4 dark styling
│   │   └── settings.ini                # GTK4 dark mode & Ioskeley font settings
│   ├── environment.d/                  # Wayland desktop environment defaults
│   ├── keyd/                           # Keyboard remap configurations
│   └── nvim/                           # LazyVim Neovim configuration
└── dot_local/
    ├── bin/
    │   ├── executable_lockscreen       # Session lock wrapper (delegates to Noctalia session lock)
    │   ├── executable_nuvio            # Display-adaptive UI scaler & hardware launcher
    │   ├── executable_qs-power         # Power CLI wrapper
    │   ├── executable_wofi-shortcuts   # System shortcuts cheat sheet (piped into noctalia dmenu)
    │   └── ...
    └── state/
        └── noctalia/
            └── settings.toml           # Unified Noctalia Shell settings & widgets
```
