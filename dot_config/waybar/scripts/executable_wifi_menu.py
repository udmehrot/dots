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

LOCK_FILE = "/tmp/waybar_wifi_menu.pid"

# Single-instance toggle & close other menus
for other in ["/tmp/waybar_volume_menu.pid", "/tmp/waybar_bluetooth_menu.pid"]:
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
    color: #9ccfd8;
}
.section-title {
    font-size: 10px;
    font-weight: bold;
    color: #908caa;
    margin-top: 10px;
    margin-bottom: 4px;
}
.network-box {
    background-color: #1f1d2e;
    border-radius: 8px;
    padding: 8px 12px;
    margin-bottom: 6px;
    transition: background-color 0.12s ease;
}
.network-box:hover {
    background-color: #26233a;
}
.network-box-active {
    background-color: #26233a;
    border-left: 3px solid #9ccfd8;
}
.btn-toggle-on {
    background-color: #26233a;
    color: #9ccfd8;
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
entry {
    background-color: #1f1d2e;
    color: #e0def4;
    border: 1px solid #26233a;
    border-radius: 6px;
    padding: 6px 10px;
}
entry:focus {
    border-color: #9ccfd8;
}
"""

class WifiMenu(Gtk.Window):
    def __init__(self):
        super().__init__()

        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.TOP)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, True)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.TOP, 44)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.RIGHT, 14)
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.ON_DEMAND)

        self.set_default_size(360, 420)
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
        icon_lbl = Gtk.Label(label="󰤨")
        icon_lbl.get_style_context().add_class("header-icon")
        title_lbl = Gtk.Label(label="Wi-Fi Networks")
        title_lbl.get_style_context().add_class("header-title")
        title_lbl.set_hexpand(True)
        title_lbl.set_halign(Gtk.Align.START)

        rescan_btn = Gtk.Button(label="󰑐")
        rescan_btn.get_style_context().add_class("btn-close")
        rescan_btn.set_tooltip_text("Rescan networks")
        rescan_btn.connect("clicked", lambda b: self.rescan())

        close_btn = Gtk.Button(label="󰅖")
        close_btn.get_style_context().add_class("btn-close")
        close_btn.connect("clicked", lambda b: self.close())

        header.pack_start(icon_lbl, False, False, 0)
        header.pack_start(title_lbl, True, True, 0)
        header.pack_end(close_btn, False, False, 0)
        header.pack_end(rescan_btn, False, False, 0)
        card.pack_start(header, False, False, 0)

        # Power Toggle Row
        power_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        power_lbl = Gtk.Label(label="Wi-Fi Power")
        power_lbl.set_halign(Gtk.Align.START)
        power_lbl.set_hexpand(True)

        is_enabled = self.is_wifi_enabled()
        self.power_btn = Gtk.Button(label="ON" if is_enabled else "OFF")
        self.power_btn.get_style_context().add_class("btn-toggle-on" if is_enabled else "btn-toggle-off")
        self.power_btn.connect("clicked", self.toggle_power)

        power_box.pack_start(power_lbl, True, True, 0)
        power_box.pack_end(self.power_btn, False, False, 0)
        card.pack_start(power_box, False, False, 0)

        card.pack_start(Gtk.Separator(), False, False, 0)

        # Networks Section
        nets_lbl = Gtk.Label(label="AVAILABLE NETWORKS")
        nets_lbl.get_style_context().add_class("section-title")
        nets_lbl.set_halign(Gtk.Align.START)
        card.pack_start(nets_lbl, False, False, 0)

        # Scrolled Window for Network List
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scrolled.set_hexpand(True)
        scrolled.set_vexpand(True)
        card.pack_start(scrolled, True, True, 0)

        self.nets_container = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        scrolled.add(self.nets_container)
        self.populate_networks()

        card.pack_start(Gtk.Separator(), False, False, 0)
        nmtui_btn = Gtk.Button(label="󰒓 Network Connections (nmtui)...")
        nmtui_btn.get_style_context().add_class("btn-action")
        nmtui_btn.connect("clicked", self.launch_nmtui)
        card.pack_start(nmtui_btn, False, False, 0)

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.close()
            return True
        return False

    def is_wifi_enabled(self):
        try:
            out = subprocess.check_output(["nmcli", "-fields", "WIFI", "g"], text=True)
            return "enabled" in out
        except Exception:
            return False

    def toggle_power(self, btn):
        enabled = self.is_wifi_enabled()
        subprocess.run(["nmcli", "radio", "wifi", "off" if enabled else "on"])
        GLib.timeout_add(300, self.refresh_state)

    def refresh_state(self):
        enabled = self.is_wifi_enabled()
        self.power_btn.set_label("ON" if enabled else "OFF")
        ctx = self.power_btn.get_style_context()
        if enabled:
            ctx.remove_class("btn-toggle-off")
            ctx.add_class("btn-toggle-on")
        else:
            ctx.remove_class("btn-toggle-on")
            ctx.add_class("btn-toggle-off")
        self.populate_networks()

    def rescan(self):
        def do_scan():
            subprocess.run(["nmcli", "dev", "wifi", "rescan"])
            GLib.idle_add(self.populate_networks)
        threading.Thread(target=do_scan, daemon=True).start()

    def get_signal_icon(self, pct):
        if pct < 25:
            return "󰤟"
        if pct < 50:
            return "󰤢"
        if pct < 75:
            return "󰤥"
        return "󰤨"

    def populate_networks(self):
        for child in self.nets_container.get_children():
            self.nets_container.remove(child)

        try:
            out = subprocess.check_output(["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list"], text=True)
            nets = []
            seen = set()
            for l in out.splitlines():
                parts = l.strip().split(":")
                if len(parts) >= 3:
                    in_use = parts[0] == "*"
                    ssid = parts[1]
                    if not ssid or ssid in seen:
                        continue
                    seen.add(ssid)
                    signal = int(parts[2]) if parts[2].isdigit() else 50
                    sec = parts[3] if len(parts) > 3 else ""
                    nets.append({"ssid": ssid, "in_use": in_use, "signal": signal, "security": sec})

            if not nets:
                empty_lbl = Gtk.Label(label="No networks found or Wi-Fi is disabled")
                empty_lbl.get_style_context().add_class("section-title")
                self.nets_container.pack_start(empty_lbl, False, False, 8)
            else:
                for net in nets[:12]:
                    ssid = net["ssid"]
                    in_use = net["in_use"]
                    sig = net["signal"]
                    sec = net["security"]

                    box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
                    box.get_style_context().add_class("network-box")
                    if in_use:
                        box.get_style_context().add_class("network-box-active")

                    icon_lbl = Gtk.Label(label=self.get_signal_icon(sig))
                    if in_use:
                        icon_lbl.get_style_context().add_class("header-icon")

                    ssid_lbl = Gtk.Label(label=ssid)
                    ssid_lbl.set_halign(Gtk.Align.START)
                    ssid_lbl.set_hexpand(True)
                    ssid_lbl.set_ellipsize(3)

                    box.pack_start(icon_lbl, False, False, 0)
                    box.pack_start(ssid_lbl, True, True, 0)

                    if sec:
                        lock_lbl = Gtk.Label(label="󰌾")
                        lock_lbl.set_opacity(0.6)
                        box.pack_start(lock_lbl, False, False, 0)

                    action_btn = Gtk.Button(label="Disconnect" if in_use else "Connect")
                    action_btn.get_style_context().add_class("btn-disconnect" if in_use else "btn-connect")
                    action_btn.connect("clicked", lambda b, s=ssid, u=in_use, sec=sec: self.handle_network_click(s, u, sec))

                    box.pack_end(action_btn, False, False, 0)
                    self.nets_container.pack_start(box, False, False, 0)
        except Exception as e:
            err_lbl = Gtk.Label(label=f"Error listing networks: {e}")
            self.nets_container.pack_start(err_lbl, False, False, 0)

        self.nets_container.show_all()

    def handle_network_click(self, ssid, in_use, security):
        if in_use:
            subprocess.run(["nmcli", "con", "down", "id", ssid])
            GLib.timeout_add(300, self.populate_networks)
            return

        # Check if network is saved
        try:
            saved = subprocess.check_output(["nmcli", "-g", "NAME", "connection", "show"], text=True).splitlines()
            if ssid in saved:
                subprocess.Popen(["nmcli", "connection", "up", "id", ssid])
                GLib.timeout_add(1000, self.populate_networks)
                return
        except Exception:
            pass

        # If unsecured, connect directly
        if not security or security == "--":
            subprocess.Popen(["nmcli", "dev", "wifi", "connect", ssid])
            GLib.timeout_add(1000, self.populate_networks)
            return

        # Prompt for password
        self.prompt_password(ssid)

    def prompt_password(self, ssid):
        dialog = Gtk.Dialog(
            title=f"Connect to {ssid}",
            parent=self,
            flags=Gtk.DialogFlags.MODAL,
            buttons=(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL, Gtk.STOCK_OK, Gtk.ResponseType.OK)
        )
        dialog.set_default_size(300, 120)
        box = dialog.get_content_area()
        box.set_spacing(8)
        lbl = Gtk.Label(label=f"Enter Wi-Fi password for {ssid}:")
        box.pack_start(lbl, False, False, 4)
        entry = Gtk.Entry()
        entry.set_visibility(False)
        entry.set_activates_default(True)
        box.pack_start(entry, False, False, 4)
        dialog.set_default_response(Gtk.ResponseType.OK)
        dialog.show_all()

        res = dialog.run()
        pwd = entry.get_text()
        dialog.destroy()

        if res == Gtk.ResponseType.OK and pwd:
            def connect_pwd():
                subprocess.run(["nmcli", "dev", "wifi", "connect", ssid, "password", pwd])
                GLib.idle_add(self.populate_networks)
            threading.Thread(target=connect_pwd, daemon=True).start()

    def launch_nmtui(self, btn):
        subprocess.Popen(["foot", "-a", "floating_control", "-T", "Network Connections (nmtui)", "nmtui"])
        self.close()

def main():
    win = WifiMenu()
    win.show_all()
    Gtk.main()

if __name__ == "__main__":
    main()
