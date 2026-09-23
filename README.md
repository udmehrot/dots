# 🌸 Rosé Pine Sway & Waybar Setup — Arch Linux

A modern, fluid, and cohesive Wayland desktop environment powered by **Sway**, **Waybar**, **SwayNC**, and **Wofi**, fully styled with the **Rosé Pine** color palette and **Ioskeley Mono** typography.

---

## 📸 Desktop Overview

* **Window Manager**: [Sway](https://swaywm.org/) (Wayland i3-compatible compositor)
* **Status Bar**: [Waybar](https://github.com/Alexays/Waybar) (Rosé Pine pills with real-time system monitors for Network throughput, CPU, Memory, Disk, plus interactive popups for Calendar & wttr.in Weather)
* **On-Screen Display (OSD)**: [SwayOSD](https://github.com/ErikReider/SwayOSD) (GTK layer-shell HUD for volume, mic, and brightness controls with Rosé Pine styling)
* **Control Center & Notifications**: [SwayNotificationCenter](https://github.com/ErikReider/SwayNotificationCenter) (`swaync` Control Center with audio mixer, per-app volume sliders, backlight, Wi-Fi networks, Bluetooth devices, and screenshot tool)
* **App Launcher & Menus**: [Wofi](https://hg.sr.ht/~scoopta/wofi) (App launcher, Clipboard history, Wi-Fi manager, Bluetooth manager, Power menu, Wallpaper selector, and System Shortcuts cheat sheet)
* **Wallpaper Daemon**: [awww](https://github.com/LGFae/awww) (Smooth animated wallpaper transitions)
* **Screenshot & Annotation**: [Swappy](https://github.com/jtheoof/swappy) + `grim` + `slurp` + `wl-clipboard` (High-contrast studio editor)
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
    sway swaylock swayidle xorg-xwayland \
    polkit polkit-gnome \
    xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk

# Status Bar, OSD, Terminals & Shells
sudo pacman -S --needed waybar swayosd foot wezterm zsh bash curl git jq btop

# Audio & Media Controls
sudo pacman -S --needed \
    pipewire pipewire-pulse pipewire-alsa wireplumber \
    pavucontrol playerctl brightnessctl

# Networking & Bluetooth
sudo pacman -S --needed \
    networkmanager network-manager-applet bluez bluez-utils

# System Daemons & Utilities
sudo pacman -S --needed \
    upower chezmoi \
    grim slurp swappy wl-clipboard cliphist

# GTK Theming & Engines
sudo pacman -S --needed \
    gtk3 gtk4 gnome-themes-extra gsettings-desktop-schemas gtk-layer-shell
```

---

### 2. AUR Helper & AUR Packages

Install an AUR helper (such as `yay` or `paru`) and install the remaining components:

```bash
# Install yay (if not already installed)
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay && makepkg -si && cd ~

# Install SwayNC, Wofi, and Awww from AUR
yay -S --needed \
    sway-notification-center \
    wofi \
    awww
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

```bash
sudo apt install -y \
    sway swaylock swayidle xwayland \
    waybar sway-notification-center wofi btop \
    foot wezterm zsh bash curl git jq \
    pipewire pipewire-pulse wireplumber pavucontrol playerctl brightnessctl \
    network-manager bluez bluez-tools upower \
    grim slurp swappy wl-clipboard \
    xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
    libgtk-3-bin libgtk-4-bin gsettings-desktop-schemas libgtk-layer-shell0
```

---

### 3. Install Latest Modern Tools on LTS

Some newer Wayland tools are best installed directly via their official installers or release binaries:

#### A. Chezmoi (Dotfile Manager)
```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
```

#### B. Cliphist (Wayland Clipboard Manager)
```bash
mkdir -p ~/.local/bin
# Download latest Linux x86_64 binary
curl -s https://api.github.com/repos/sentriz/cliphist/releases/latest \
  | jq -r '.assets[] | select(.name | test("linux_amd64")) | .browser_download_url' \
  | wget -qi - -O ~/.local/bin/cliphist
chmod +x ~/.local/bin/cliphist
```

#### C. Awww (Smooth Animated Wallpaper Daemon)
Install via Rust Cargo (or download precompiled binary from [awww releases](https://github.com/LGFae/awww/releases)):
```bash
sudo apt install -y cargo libwayland-dev libxkbcommon-dev
cargo install awww
# Ensure ~/.cargo/bin or ~/.local/bin is in your PATH
```

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
| Shortcut | Action |
| :--- | :--- |
| **<kbd>Super</kbd> + <kbd>Return</kbd>** | Launch Foot Terminal |
| **<kbd>Super</kbd> + <kbd>D</kbd>** | Application Launcher (Wofi) |
| **<kbd>Super</kbd> + <kbd>K</kbd>** | System Shortcuts & Keybinds List (Wofi) |
| **<kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>V</kbd>** | Clipboard History Manager (`cliphist`) |
| **<kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>W</kbd>** | Wi-Fi Network Selector (`nmtui` in floating window) |
| **<kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>B</kbd>** | Wallpaper Switcher Menu (`awww`) |
| **<kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>B</kbd>** | Set Random Wallpaper |
| **<kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>E</kbd>** | Power & Session Menu (Lock, Suspend, Reboot, Shutdown) |
| **<kbd>Super</kbd> + <kbd>N</kbd>** / **<kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>N</kbd>** | Toggle Notification Center (`swaync`) |

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

### 📸 Screenshots
| Shortcut | Action | Output |
| :--- | :--- | :--- |
| **<kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd>**<br>or **<kbd>Super</kbd> + <kbd>Print</kbd>** | Select Area $\rightarrow$ Annotate in Swappy | Clipboard / `~/Pictures/Screenshots/` |
| **<kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>S</kbd>** | Quick Area Selection | Directly copied to Clipboard |
| **<kbd>Print</kbd>** or **<kbd>Ctrl</kbd> + <kbd>Print</kbd>** | Quick Full Screen | Directly copied to Clipboard |
| **<kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>Print</kbd>** | Area Selection | Saved to `~/Pictures/Screenshots/` |
| **<kbd>Shift</kbd> + <kbd>Print</kbd>** | Full Screen | Saved to `~/Pictures/Screenshots/` |

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
    └── bin/
        ├── cliphist-daemon             # Background clipboard watcher
        ├── executable_lockscreen       # Random lockscreen wallpaper script
        ├── executable_nuvio            # Display-adaptive UI scaler & hardware launcher
        ├── executable_wofi-bluetooth   # Bluetooth device manager & pairer
        ├── executable_wofi-clipboard   # Clipboard search and paste menu
        ├── executable_wofi-power       # Power & session action menu
        ├── executable_wofi-shortcuts   # System shortcuts cheat sheet
        ├── executable_wofi-wallpaper   # Animated wallpaper selector
        └── executable_wofi-wifi        # Wi-Fi network selector
```
