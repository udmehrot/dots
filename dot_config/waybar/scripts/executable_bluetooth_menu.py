#!/usr/bin/env python3
import os
import signal
import subprocess
import sys
import threading
import atexit
import gi

gi.require_version('Gtk', '3.0')
gi.require_version('Gdk', '3.0')
gi.require_version('GtkLayerShell', '0.1')
from gi.repository import Gtk, Gdk, GtkLayerShell, GLib

LOCK_FILE = "/tmp/waybar_bluetooth_menu.pid"

# Single-instance toggle & close other menus
for other in ["/tmp/waybar_volume_menu.pid", "/tmp/waybar_wifi_menu.pid"]:
    if os.path.exists(other):
        try:
            with open(other, "r") as f:
                p = int(f.read().strip())
            os.kill(p, signal.SIGTERM)
            os.remove(other)
        except Exception:
            pass

if os.path.exists(LOCK_FILE):
    try:
        with open(LOCK_FILE, "r") as f:
            pid = int(f.read().strip())
        os.remove(LOCK_FILE)
        os.kill(pid, signal.SIGTERM)
        sys.exit(0)
    except Exception:
        pass

with open(LOCK_FILE, "w") as f:
    f.write(str(os.getpid()))

def cleanup():
    if os.path.exists(LOCK_FILE):
        try:
            os.remove(LOCK_FILE)
        except Exception:
            pass

atexit.register(cleanup)

CSS = """
window {
    background-color: transparent;
}
#card {
    background-color: #191724;
    border: 1px solid #26233a;
    border-radius: 12px;
    padding: 16px;
}
label {
    font-family: "IoskeleyMono Nerd Font Mono", monospace;
    color: #e0def4;
}
.header-title {
    font-weight: bold;
    font-size: 14px;
    color: #ebbcba;
}
.header-icon {
    font-size: 16px;
    color: #c4a7e7;
}
.section-title {
    font-size: 10px;
    font-weight: bold;
    color: #908caa;
    margin-top: 10px;
    margin-bottom: 4px;
}
.device-box {
    background-color: #1f1d2e;
    border-radius: 8px;
    padding: 8px 12px;
    margin-bottom: 6px;
    transition: background-color 0.12s ease;
}
.device-box:hover {
    background-color: #26233a;
}
.device-box-active {
    background-color: #26233a;
    border-left: 3px solid #c4a7e7;
}
.btn-toggle-on {
    background-color: #26233a;
    color: #ebbcba;
    font-weight: bold;
    border-radius: 6px;
    padding: 4px 10px;
}
.btn-toggle-off {
    background-color: #1f1d2e;
    color: #6e6a86;
    border-radius: 6px;
    padding: 4px 10px;
}
.btn-connect {
    background-color: #26233a;
    color: #9ccfd8;
    border-radius: 6px;
    padding: 4px 8px;
    font-size: 11px;
}
.btn-connect:hover {
    background-color: #ebbcba;
    color: #191724;
}
.btn-disconnect {
    background-color: #1f1d2e;
    color: #eb6f92;
    border-radius: 6px;
    padding: 4px 8px;
    font-size: 11px;
}
.btn-disconnect:hover {
    background-color: #eb6f92;
    color: #191724;
}
.btn-action {
    background-color: #1f1d2e;
    color: #908caa;
    border-radius: 6px;
    padding: 6px 12px;
    font-size: 11px;
}
.btn-action:hover {
    background-color: #26233a;
    color: #ebbcba;
}
.btn-close {
    background-color: transparent;
    color: #908caa;
    border-radius: 6px;
    padding: 2px 6px;
}
.btn-close:hover {
    background-color: #26233a;
    color: #eb6f92;
}
separator {
    background-color: #26233a;
    min-height: 1px;
    margin: 8px 0;
}
"""

class BluetoothMenu(Gtk.Window):
    def __init__(self):
        super().__init__()

        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.TOP)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, True)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.TOP, 44)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.RIGHT, 14)
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.ON_DEMAND)

        self.set_default_size(340, -1)
        self.connect("destroy", Gtk.main_quit)
        self.connect("key-press-event", self.on_key_press)

        css_provider = Gtk.CssProvider()
        css_provider.load_from_data(CSS.encode())
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        card.set_name("card")
        self.add(card)

        # Header
        header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        icon_lbl = Gtk.Label(label="󰂯")
        icon_lbl.get_style_context().add_class("header-icon")
        title_lbl = Gtk.Label(label="Bluetooth")
        title_lbl.get_style_context().add_class("header-title")
        title_lbl.set_hexpand(True)
        title_lbl.set_halign(Gtk.Align.START)

        close_btn = Gtk.Button(label="󰅖")
        close_btn.get_style_context().add_class("btn-close")
        close_btn.connect("clicked", lambda b: self.close())

        header.pack_start(icon_lbl, False, False, 0)
        header.pack_start(title_lbl, True, True, 0)
        header.pack_end(close_btn, False, False, 0)
        card.pack_start(header, False, False, 0)

        # Power Toggle Row
        power_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        power_lbl = Gtk.Label(label="Bluetooth Power")
        power_lbl.set_halign(Gtk.Align.START)
        power_lbl.set_hexpand(True)

        is_powered = self.is_powered()
        self.power_btn = Gtk.Button(label="ON" if is_powered else "OFF")
        self.power_btn.get_style_context().add_class("btn-toggle-on" if is_powered else "btn-toggle-off")
        self.power_btn.connect("clicked", self.toggle_power)

        power_box.pack_start(power_lbl, True, True, 0)
        power_box.pack_end(self.power_btn, False, False, 0)
        card.pack_start(power_box, False, False, 0)

        # Separator
        card.pack_start(Gtk.Separator(), False, False, 0)

        # Devices Section
        devs_lbl = Gtk.Label(label="PAIRED & CONNECTED DEVICES")
        devs_lbl.get_style_context().add_class("section-title")
        devs_lbl.set_halign(Gtk.Align.START)
        card.pack_start(devs_lbl, False, False, 0)

        self.devs_container = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        card.pack_start(self.devs_container, False, False, 0)
        self.populate_devices()

        # Bottom Action
        card.pack_start(Gtk.Separator(), False, False, 0)
        mgr_btn = Gtk.Button(label="󰒓 Bluetooth Manager (bluetoothctl)...")
        mgr_btn.get_style_context().add_class("btn-action")
        mgr_btn.connect("clicked", self.launch_manager)
        card.pack_start(mgr_btn, False, False, 0)

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.close()
            return True
        return False

    def is_powered(self):
        try:
            out = subprocess.check_output(["bluetoothctl", "show"], text=True)
            return "Powered: yes" in out
        except Exception:
            return False

    def toggle_power(self, btn):
        powered = self.is_powered()
        new_state = "off" if powered else "on"
        subprocess.run(["bluetoothctl", "power", new_state])
        GLib.timeout_add(200, self.refresh_state)

    def refresh_state(self):
        powered = self.is_powered()
        self.power_btn.set_label("ON" if powered else "OFF")
        ctx = self.power_btn.get_style_context()
        if powered:
            ctx.remove_class("btn-toggle-off")
            ctx.add_class("btn-toggle-on")
        else:
            ctx.remove_class("btn-toggle-on")
            ctx.add_class("btn-toggle-off")
        self.populate_devices()

    def populate_devices(self):
        for child in self.devs_container.get_children():
            self.devs_container.remove(child)

        try:
            p_out = subprocess.check_output(["bluetoothctl", "devices"], text=True)
            c_out = subprocess.check_output(["bluetoothctl", "devices", "Connected"], text=True)
            conn_macs = set()
            for l in c_out.splitlines():
                parts = l.strip().split()
                if len(parts) >= 2:
                    conn_macs.add(parts[1])

            devs = []
            for l in p_out.splitlines():
                parts = l.strip().split(maxsplit=2)
                if len(parts) >= 3:
                    mac = parts[1]
                    name = parts[2]
                    devs.append({"mac": mac, "name": name, "connected": mac in conn_macs})

            if not devs:
                empty_lbl = Gtk.Label(label="No paired devices")
                empty_lbl.get_style_context().add_class("header-subtitle")
                self.devs_container.pack_start(empty_lbl, False, False, 8)
            else:
                for dev in devs:
                    mac = dev["mac"]
                    name = dev["name"]
                    conn = dev["connected"]

                    box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
                    box.get_style_context().add_class("device-box")
                    if conn:
                        box.get_style_context().add_class("device-box-active")

                    icon = "󰋋" if any(w in name.lower() for w in ["headphone", "shokz", "space", "buds", "ear"]) else ("󰌌" if "key" in name.lower() or "nuphy" in name.lower() else "󰂯")
                    if conn:
                        icon = "󰂱"

                    icon_lbl = Gtk.Label(label=icon)
                    if conn:
                        icon_lbl.get_style_context().add_class("header-icon")

                    name_lbl = Gtk.Label(label=name)
                    name_lbl.set_halign(Gtk.Align.START)
                    name_lbl.set_hexpand(True)
                    name_lbl.set_ellipsize(3)

                    action_btn = Gtk.Button(label="Disconnect" if conn else "Connect")
                    action_btn.get_style_context().add_class("btn-disconnect" if conn else "btn-connect")
                    action_btn.connect("clicked", lambda b, m=mac, c=conn: self.toggle_device(m, c))

                    box.pack_start(icon_lbl, False, False, 0)
                    box.pack_start(name_lbl, True, True, 0)
                    box.pack_end(action_btn, False, False, 0)
                    self.devs_container.pack_start(box, False, False, 0)
        except Exception as e:
            err_lbl = Gtk.Label(label=f"Error listing devices: {e}")
            self.devs_container.pack_start(err_lbl, False, False, 0)

        self.devs_container.show_all()

    def toggle_device(self, mac, connected):
        cmd = ["bluetoothctl", "disconnect" if connected else "connect", mac]
        def run():
            subprocess.run(cmd)
            GLib.idle_add(self.populate_devices)
        threading.Thread(target=run, daemon=True).start()

    def launch_manager(self, btn):
        subprocess.Popen(["foot", "-a", "floating_control", "-T", "Bluetooth (bluetoothctl)", "bluetoothctl"])
        self.close()

def main():
    win = BluetoothMenu()
    win.show_all()
    Gtk.main()

if __name__ == "__main__":
    main()
