#!/usr/bin/env python3
import os
import re
import signal
import subprocess
import sys
import atexit
import gi

gi.require_version('Gtk', '3.0')
gi.require_version('Gdk', '3.0')
gi.require_version('GtkLayerShell', '0.1')
from gi.repository import Gtk, Gdk, GtkLayerShell, GLib

LOCK_FILE = "/tmp/waybar_volume_menu.pid"

# Single-instance toggle & close other menus
for other in ["/tmp/waybar_bluetooth_menu.pid", "/tmp/waybar_wifi_menu.pid"]:
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
.sink-box {
    background-color: #1f1d2e;
    border-radius: 8px;
    padding: 8px 12px;
    margin-bottom: 6px;
    transition: background-color 0.12s ease;
}
.sink-box:hover {
    background-color: #26233a;
}
.sink-box-active {
    background-color: #26233a;
    border-left: 3px solid #9ccfd8;
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
.btn-mute {
    background-color: #1f1d2e;
    color: #9ccfd8;
    border-radius: 6px;
    padding: 4px 8px;
    font-size: 16px;
}
.btn-mute:hover {
    background-color: #26233a;
    color: #ebbcba;
}
.btn-mute-active {
    color: #eb6f92;
}
scale trough {
    background-color: #26233a;
    border-radius: 4px;
    min-height: 8px;
}
scale highlight {
    background-color: #9ccfd8;
    border-radius: 4px;
}
scale slider {
    background-color: #e0def4;
    border-radius: 50%;
    min-width: 16px;
    min-height: 16px;
}
separator {
    background-color: #26233a;
    min-height: 1px;
    margin: 8px 0;
}
"""

class VolumeMenu(Gtk.Window):
    def __init__(self):
        super().__init__()

        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.TOP)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, True)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.TOP, 44)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.RIGHT, 14)
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.ON_DEMAND)

        self.set_default_size(360, -1)
        self.connect("destroy", Gtk.main_quit)
        self.connect("key-press-event", self.on_key_press)

        # Style provider
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
        icon_lbl = Gtk.Label(label="󰕾")
        icon_lbl.get_style_context().add_class("header-icon")
        title_lbl = Gtk.Label(label="Audio & Volume")
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

        # Volume slider section
        vol, is_muted = self.get_volume_info()
        vol_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        vol_box.set_margin_top(4)

        self.mute_btn = Gtk.Button(label="󰝟" if is_muted else "󰕾")
        self.mute_btn.get_style_context().add_class("btn-mute")
        if is_muted:
            self.mute_btn.get_style_context().add_class("btn-mute-active")
        self.mute_btn.connect("clicked", self.toggle_mute)
        vol_box.pack_start(self.mute_btn, False, False, 0)

        self.scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 1)
        self.scale.set_value(vol * 100)
        self.scale.set_hexpand(True)
        self.scale.set_draw_value(False)
        self.scale.connect("value-changed", self.on_scale_changed)
        vol_box.pack_start(self.scale, True, True, 0)

        self.vol_lbl = Gtk.Label(label=f"{int(vol * 100)}%")
        self.vol_lbl.set_size_request(45, -1)
        vol_box.pack_start(self.vol_lbl, False, False, 0)
        card.pack_start(vol_box, False, False, 0)

        # Separator
        card.pack_start(Gtk.Separator(), False, False, 0)

        # Output Devices Section
        sinks_lbl = Gtk.Label(label="OUTPUT DEVICES")
        sinks_lbl.get_style_context().add_class("section-title")
        sinks_lbl.set_halign(Gtk.Align.START)
        card.pack_start(sinks_lbl, False, False, 0)

        self.sinks_container = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        card.pack_start(self.sinks_container, False, False, 0)
        self.populate_sinks()

        # Bottom Action
        card.pack_start(Gtk.Separator(), False, False, 0)
        mixer_btn = Gtk.Button(label="󰒓 Audio Control (pavucontrol)...")
        mixer_btn.get_style_context().add_class("btn-action")
        mixer_btn.connect("clicked", self.launch_mixer)
        card.pack_start(mixer_btn, False, False, 0)

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.close()
            return True
        return False

    def get_volume_info(self):
        try:
            out = subprocess.check_output(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"], text=True).strip()
            is_muted = "[MUTED]" in out
            m = re.search(r"Volume:\s*([\d\.]+)", out)
            vol = float(m.group(1)) if m else 0.5
            return vol, is_muted
        except Exception:
            return 0.5, False

    def toggle_mute(self, btn):
        subprocess.run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
        vol, is_muted = self.get_volume_info()
        self.mute_btn.set_label("󰝟" if is_muted else "󰕾")
        ctx = self.mute_btn.get_style_context()
        if is_muted:
            ctx.add_class("btn-mute-active")
        else:
            ctx.remove_class("btn-mute-active")

    def on_scale_changed(self, scale):
        val = scale.get_value()
        self.vol_lbl.set_text(f"{int(val)}%")
        subprocess.run(["wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SINK@", f"{val / 100:.2f}"])

    def populate_sinks(self):
        for child in self.sinks_container.get_children():
            self.sinks_container.remove(child)

        try:
            out = subprocess.check_output(["wpctl", "status"], text=True)
            in_sinks = False
            for line in out.splitlines():
                if "Sinks:" in line:
                    in_sinks = True
                    continue
                if in_sinks:
                    if any(k in line for k in ["Sources:", "Filters:", "Streams:", "Settings"]) or (line and line[0] not in " │├└"):
                        break
                    m = re.search(r"([*]?)\s*(\d+)\.\s+(.*?)\s+\[vol:\s*([\d\.]+)\]", line)
                    if m:
                        is_def = m.group(1) == "*"
                        sink_id = int(m.group(2))
                        name = m.group(3).strip()

                        sink_btn = Gtk.Button()
                        sink_btn.get_style_context().add_class("sink-box")
                        if is_def:
                            sink_btn.get_style_context().add_class("sink-box-active")

                        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
                        icon = "󰋋" if any(w in name.lower() for w in ["headphone", "shokz", "buds", "ear"]) else "󰕾"
                        icon_widget = Gtk.Label(label=icon)
                        icon_widget.set_size_request(20, -1)
                        if is_def:
                            icon_widget.get_style_context().add_class("header-icon")

                        lbl = Gtk.Label(label=name)
                        lbl.set_halign(Gtk.Align.START)
                        lbl.set_hexpand(True)
                        lbl.set_ellipsize(3) # PANGO_ELLIPSIZE_END

                        row.pack_start(icon_widget, False, False, 0)
                        row.pack_start(lbl, True, True, 0)

                        if is_def:
                            check = Gtk.Label(label="󰄬")
                            check.get_style_context().add_class("header-title")
                            row.pack_end(check, False, False, 0)

                        sink_btn.add(row)
                        sink_btn.connect("clicked", lambda b, s_id=sink_id: self.select_sink(s_id))
                        self.sinks_container.pack_start(sink_btn, False, False, 0)
        except Exception as e:
            err_lbl = Gtk.Label(label=f"Could not load sinks: {e}")
            self.sinks_container.pack_start(err_lbl, False, False, 0)

        self.sinks_container.show_all()

    def select_sink(self, sink_id):
        subprocess.run(["wpctl", "set-default", str(sink_id)])
        GLib.timeout_add(100, self.populate_sinks)
        vol, is_muted = self.get_volume_info()
        self.scale.set_value(vol * 100)
        self.vol_lbl.set_text(f"{int(vol * 100)}%")

    def launch_mixer(self, btn):
        subprocess.Popen(["pavucontrol"])
        self.close()

def main():
    win = VolumeMenu()
    win.show_all()
    Gtk.main()

if __name__ == "__main__":
    main()
