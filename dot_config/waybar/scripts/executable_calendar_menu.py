#!/usr/bin/env python3
import os
os.environ["GTK_THEME"] = "Adwaita:dark"
import signal
import sys
import atexit
from datetime import datetime
import gi

gi.require_version('Gtk', '3.0')
gi.require_version('Gdk', '3.0')
gi.require_version('GtkLayerShell', '0.1')
from gi.repository import Gtk, Gdk, GtkLayerShell, GLib

LOCK_FILE = "/tmp/waybar_calendar_menu.pid"

# Close weather menu if open
if os.path.exists("/tmp/waybar_weather_menu.pid"):
    try:
        with open("/tmp/waybar_weather_menu.pid", "r") as f:
            p = int(f.read().strip())
        os.kill(p, signal.SIGTERM)
        os.remove("/tmp/waybar_weather_menu.pid")
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
#overlay {
    background-color: transparent;
}
#card {
    background-color: #191724;
    border: 1px solid #26233a;
    border-radius: 12px;
    padding: 12px 14px;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.6);
}
label {
    font-family: "IoskeleyMono Nerd Font Mono", monospace;
    color: #e0def4;
}
.header-date {
    font-size: 13px;
    font-weight: bold;
    color: #ebbcba;
}
.header-icon {
    font-size: 14px;
    color: #c4a7e7;
}
.clock-display {
    font-size: 16px;
    font-weight: bold;
    color: #9ccfd8;
    background-color: #1f1d2e;
    border-radius: 6px;
    padding: 6px 10px;
    margin-top: 2px;
}
button {
    background-image: none;
    background-color: transparent;
    border: none;
    box-shadow: none;
    text-shadow: none;
    -gtk-icon-shadow: none;
    outline: none;
}
button:hover,
button:active,
button:focus {
    background-image: none;
    box-shadow: none;
    outline: none;
}
.btn-close {
    background-image: none;
    background-color: transparent;
    border: none;
    box-shadow: none;
    color: #908caa;
    border-radius: 6px;
    padding: 2px 6px;
    font-size: 14px;
}
.btn-close label {
    color: inherit;
    font-size: inherit;
    font-family: "IoskeleyMono Nerd Font Mono", monospace;
}
.btn-close:hover {
    background-image: none;
    background-color: #26233a;
    color: #eb6f92;
}
.btn-close:hover label {
    color: #eb6f92;
}
calendar {
    font-family: "IoskeleyMono Nerd Font Mono", monospace;
    font-size: 13px;
    background-color: #191724;
    color: #e0def4;
    border: 1px solid #26233a;
    border-radius: 8px;
    padding: 6px;
}
calendar:selected {
    background-color: #ebbcba;
    color: #191724;
    border-radius: 4px;
    font-weight: bold;
}
calendar.header {
    border-bottom: 1px solid #26233a;
    font-size: 13px;
    font-weight: bold;
    color: #ebbcba;
}
calendar.button {
    background-image: none;
    background-color: transparent;
    border: none;
    box-shadow: none;
    color: #e0def4;
    font-size: 13px;
}
calendar.button:hover {
    background-image: none;
    color: #ebbcba;
    background-color: #26233a;
    border-radius: 4px;
}
calendar:indeterminate {
    color: #6e6a86;
}
calendar.highlight {
    color: #9ccfd8;
    font-weight: bold;
}
separator {
    background-color: #26233a;
    min-height: 1px;
    margin: 6px 0;
}
"""

class CalendarMenu(Gtk.Window):
    def __init__(self):
        super().__init__()

        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.TOP)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.BOTTOM, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.LEFT, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, True)
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.ON_DEMAND)

        self.connect("destroy", Gtk.main_quit)
        self.connect("key-press-event", self.on_key_press)

        css_provider = Gtk.CssProvider()
        css_provider.load_from_data(CSS.encode())
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        # Fullscreen transparent overlay to capture outside clicks
        self.overlay = Gtk.EventBox()
        self.overlay.set_name("overlay")
        self.overlay.set_visible_window(False)
        self.overlay.connect("button-press-event", self.on_bg_click)
        self.add(self.overlay)

        # Centered Popup Card
        self.card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        self.card.set_name("card")
        self.card.set_halign(Gtk.Align.CENTER)
        self.card.set_valign(Gtk.Align.START)
        self.card.set_margin_top(46)
        self.card.set_size_request(310, -1)
        self.overlay.add(self.card)

        # Header
        header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        icon_lbl = Gtk.Label(label="󰃮")
        icon_lbl.get_style_context().add_class("header-icon")

        now = datetime.now()
        date_str = now.strftime("%A, %B %d, %Y")
        title_lbl = Gtk.Label(label=date_str)
        title_lbl.get_style_context().add_class("header-date")
        title_lbl.set_hexpand(True)
        title_lbl.set_halign(Gtk.Align.START)

        close_btn = Gtk.Button(label="󰅖")
        close_btn.get_style_context().add_class("btn-close")
        close_btn.connect("clicked", lambda b: self.close())

        header.pack_start(icon_lbl, False, False, 0)
        header.pack_start(title_lbl, True, True, 0)
        header.pack_end(close_btn, False, False, 0)
        self.card.pack_start(header, False, False, 0)

        self.card.pack_start(Gtk.Separator(), False, False, 0)

        # Calendar Widget
        self.calendar = Gtk.Calendar()
        self.calendar.set_display_options(
            Gtk.CalendarDisplayOptions.SHOW_HEADING |
            Gtk.CalendarDisplayOptions.SHOW_DAY_NAMES |
            Gtk.CalendarDisplayOptions.SHOW_WEEK_NUMBERS
        )
        self.card.pack_start(self.calendar, True, True, 0)

        # Digital Clock Display at bottom
        self.clock_lbl = Gtk.Label(label=now.strftime("%H:%M:%S"))
        self.clock_lbl.get_style_context().add_class("clock-display")
        self.card.pack_start(self.clock_lbl, False, False, 0)

        GLib.timeout_add(1000, self.update_clock)

    def on_bg_click(self, widget, event):
        coords = self.card.translate_coordinates(self.overlay, 0, 0)
        if coords:
            cx, cy = coords
            alloc = self.card.get_allocation()
            cw, ch = alloc.width, alloc.height
            if not (cx <= event.x <= cx + cw and cy <= event.y <= cy + ch):
                self.close()
                return True
        else:
            self.close()
            return True
        return False

    def update_clock(self):
        self.clock_lbl.set_text(datetime.now().strftime("%H:%M:%S"))
        return True

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.close()
            return True
        return False

def main():
    win = CalendarMenu()
    win.show_all()
    Gtk.main()

if __name__ == "__main__":
    main()
