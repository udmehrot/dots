# 🌸 Rosé Pine Sway & Quickshell Setup — Arch Linux

A modern, fluid, and cohesive Wayland desktop environment powered by **Sway**, **Quickshell**, **SwayNC**, and **Wofi**, fully styled with the **Rosé Pine** color palette and **Ioskeley Mono** typography.

---

## 📸 Desktop Overview

* **Window Manager**: [Sway](https://swaywm.org/) (Wayland i3-compatible compositor)
* **Status Bar**: [Quickshell](https://quickshell.outfoxxed.me/) (`shell.qml` with interactive native dropdowns for Volume Sinks, Bluetooth, Wi-Fi, Calendar, Weather, and Battery)
* **Notification Daemon**: [SwayNotificationCenter](https://github.com/ErikReider/SwayNotificationCenter) (`swaync` with rich widgets & Rosé Pine CSS)
* **App Launcher & Menus**: [Wofi](https://hg.sr.ht/~scoopta/wofi) (App launcher, Clipboard history, Wi-Fi manager, Power menu, Wallpaper selector, and System Shortcuts cheat sheet)
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

# Terminals & Shells
sudo pacman -S --needed foot wezterm zsh bash curl git jq

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
    gtk3 gtk4 gnome-themes-extra gsettings-desktop-schemas
```

---

### 2. AUR Helper & AUR Packages

Install an AUR helper (such as `yay` or `paru`) and install the remaining components:

```bash
# Install yay (if not already installed)
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay && makepkg -si && cd ~

# Install Quickshell, SwayNC, Wofi, and Awww from AUR
yay -S --needed \
    quickshell \
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
├── dot_bashrc                          # Bash configuration
├── dot_bash_profile                    # Bash profile & Wayland environment
├── dot_zshenv                          # Zsh environment variables
├── dot_zshrc                           # Zsh interactive configuration
├── dot_config/
│   ├── sway/
│   │   └── config                      # Sway window manager configuration
│   ├── quickshell/
│   │   └── shell.qml                   # Quickshell top bar & interactive applets
│   ├── swaync/
│   │   ├── config.json                 # SwayNotificationCenter widget layout
│   │   └── style.css                   # SwayNC Rosé Pine CSS theme
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
        ├── wofi-clipboard              # Clipboard search and paste menu
        ├── wofi-power                  # Power & session action menu
        ├── wofi-shortcuts              # System shortcuts cheat sheet
        ├── wofi-wallpaper              # Animated wallpaper selector
        └── wofi-wifi                   # Wi-Fi network selector
```
