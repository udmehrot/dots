#!/usr/bin/env python3
import json
import os
os.environ["GTK_THEME"] = "Adwaita:dark"
import signal
import sys
import threading
import atexit
from datetime import datetime
import gi

gi.require_version('Gtk', '3.0')
gi.require_version('Gdk', '3.0')
gi.require_version('GtkLayerShell', '0.1')
from gi.repository import Gtk, Gdk, GtkLayerShell, GLib

LOCK_FILE = "/tmp/waybar_weather_menu.pid"

# Close calendar menu if open
if os.path.exists("/tmp/waybar_calendar_menu.pid"):
    try:
        with open("/tmp/waybar_calendar_menu.pid", "r") as f:
            p = int(f.read().strip())
        os.kill(p, signal.SIGTERM)
        os.remove("/tmp/waybar_calendar_menu.pid")
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

CACHE_FILE = "/tmp/waybar_weather_cache.json"

def parse_weather_icon(desc):
    if not desc:
        return "󰖐"
    lower = desc.lower()
    if "sun" in lower or "clear" in lower:
        return "󰖙"
    if "partly" in lower:
        return "󰖕"
    if "thunder" in lower or "storm" in lower:
        return "󰙾"
    if any(k in lower for k in ["snow", "ice", "sleet", "blizzard"]):
        return "󰖘"
    if any(k in lower for k in ["rain", "drizzle", "shower"]):
        return "󰖗"
    if any(k in lower for k in ["fog", "mist", "haze"]):
        return "󰖑"
    if "cloud" in lower or "overcast" in lower:
        return "󰖐"
    return "󰖐"

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
.header-title {
    font-size: 13px;
    font-weight: bold;
    color: #e0def4;
}
.header-icon {
    font-size: 14px;
    color: #ebbcba;
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
.btn-icon {
    background-image: none;
    background-color: transparent;
    border: none;
    box-shadow: none;
    color: #e0def4;
    border-radius: 6px;
    padding: 2px 6px;
    font-size: 14px;
}
.btn-icon label {
    color: inherit;
    font-size: inherit;
    font-family: "IoskeleyMono Nerd Font Mono", monospace;
}
.btn-icon:hover {
    background-image: none;
    background-color: #26233a;
    color: #ebbcba;
}
.btn-icon:hover label {
    color: #ebbcba;
}
.btn-close {
    color: #908caa;
}
.btn-close:hover {
    background-image: none;
    background-color: #26233a;
    color: #eb6f92;
}
.btn-close:hover label {
    color: #eb6f92;
}
.weather-main-card {
    background-color: #1f1d2e;
    border-radius: 8px;
    padding: 10px 12px;
    margin-top: 4px;
    margin-bottom: 4px;
}
.big-icon {
    font-size: 34px;
    color: #f6c177;
}
.big-temp {
    font-size: 22px;
    font-weight: bold;
    color: #e0def4;
}
.desc-text {
    font-size: 11px;
    color: #908caa;
}
.metrics-card {
    background-color: #1f1d2e;
    border-radius: 8px;
    padding: 6px 4px;
}
.metric-title {
    font-size: 9px;
    font-weight: bold;
    color: #908caa;
}
.metric-val-humidity {
    font-size: 12px;
    font-weight: bold;
    color: #9ccfd8;
}
.metric-val-wind {
    font-size: 12px;
    font-weight: bold;
    color: #c4a7e7;
}
.metric-val-uv {
    font-size: 12px;
    font-weight: bold;
    color: #f6c177;
}
.section-title {
    font-size: 10px;
    font-weight: bold;
    color: #908caa;
    margin-top: 4px;
    margin-bottom: 2px;
}
.forecast-card {
    background-color: #1f1d2e;
    border-radius: 8px;
    padding: 6px 4px;
}
.forecast-day-today {
    font-size: 11px;
    font-weight: bold;
    color: #ebbcba;
}
.forecast-day {
    font-size: 11px;
    font-weight: bold;
    color: #e0def4;
}
.forecast-icon {
    font-size: 18px;
    color: #f6c177;
    margin: 2px 0;
}
.forecast-temp {
    font-size: 10px;
    font-weight: bold;
    color: #908caa;
}
.forecast-desc {
    font-size: 9px;
    color: #6e6a86;
}
separator {
    background-color: #26233a;
    min-height: 1px;
    margin: 6px 0;
}
"""

class WeatherMenu(Gtk.Window):
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
        self.card.set_size_request(320, -1)
        self.overlay.add(self.card)

        self.render_content()

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

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.close()
            return True
        return False

    def load_weather_data(self):
        if os.path.exists(CACHE_FILE):
            try:
                with open(CACHE_FILE, "r") as f:
                    return json.load(f)
            except Exception:
                pass
        return None

    def render_content(self):
        for child in self.card.get_children():
            self.card.remove(child)

        data = self.load_weather_data()
        if not data or "current_condition" not in data:
            err_lbl = Gtk.Label(label="Weather data loading or unavailable.\nClick refresh to try again.")
            err_lbl.set_size_request(-1, 100)
            self.card.pack_start(err_lbl, True, True, 0)
            self.card.show_all()
            return

        curr = data["current_condition"][0]
        desc = curr.get("weatherDesc", [{}])[0].get("value", "").strip()
        temp_f = curr.get("temp_F", "--")
        feels_like_f = curr.get("FeelsLikeF", "--")
        humidity = curr.get("humidity", "--")
        wind = f"{curr.get('windspeedMiles', '--')} mph {curr.get('winddir16Point', '')}".strip()
        uv = curr.get("uvIndex", "--")
        icon = parse_weather_icon(desc)

        loc = "Current Location"
        if "nearest_area" in data and data["nearest_area"]:
            area = data["nearest_area"][0]
            area_name = area.get("areaName", [{}])[0].get("value", "")
            region = area.get("region", [{}])[0].get("value", "")
            loc = f"{area_name}, {region}" if region else area_name

        # Header: Location & Actions
        header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        loc_icon = Gtk.Label(label="󰍎")
        loc_icon.get_style_context().add_class("header-icon")

        loc_lbl = Gtk.Label(label=loc)
        loc_lbl.get_style_context().add_class("header-title")
        loc_lbl.set_hexpand(True)
        loc_lbl.set_halign(Gtk.Align.START)
        loc_lbl.set_ellipsize(3)

        refresh_btn = Gtk.Button(label="󰑐")
        refresh_btn.get_style_context().add_class("btn-icon")
        refresh_btn.set_tooltip_text("Refresh weather")
        refresh_btn.connect("clicked", lambda b: self.refresh_weather())

        close_btn = Gtk.Button(label="󰅖")
        close_btn.get_style_context().add_class("btn-icon")
        close_btn.get_style_context().add_class("btn-close")
        close_btn.connect("clicked", lambda b: self.close())

        header.pack_start(loc_icon, False, False, 0)
        header.pack_start(loc_lbl, True, True, 0)
        header.pack_end(close_btn, False, False, 0)
        header.pack_end(refresh_btn, False, False, 0)
        self.card.pack_start(header, False, False, 0)

        # Current Weather Card
        main_card = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=16)
        main_card.get_style_context().add_class("weather-main-card")

        big_icon_lbl = Gtk.Label(label=icon)
        big_icon_lbl.get_style_context().add_class("big-icon")
        main_card.pack_start(big_icon_lbl, False, False, 4)

        temp_col = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        temp_col.set_valign(Gtk.Align.CENTER)

        big_temp_lbl = Gtk.Label(label=f"{temp_f}°F")
        big_temp_lbl.get_style_context().add_class("big-temp")
        big_temp_lbl.set_halign(Gtk.Align.START)

        desc_lbl = Gtk.Label(label=f"{desc} • Feels like {feels_like_f}°F")
        desc_lbl.get_style_context().add_class("desc-text")
        desc_lbl.set_halign(Gtk.Align.START)

        temp_col.pack_start(big_temp_lbl, False, False, 0)
        temp_col.pack_start(desc_lbl, False, False, 0)
        main_card.pack_start(temp_col, True, True, 0)
        self.card.pack_start(main_card, False, False, 0)

        # Metrics Grid (Humidity, Wind, UV)
        metrics_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        metrics_box.set_homogeneous(True)

        # Humidity Card
        hum_card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        hum_card.get_style_context().add_class("metrics-card")
        hum_title = Gtk.Label(label="HUMIDITY")
        hum_title.get_style_context().add_class("metric-title")
        hum_val = Gtk.Label(label=f"{humidity}%")
        hum_val.get_style_context().add_class("metric-val-humidity")
        hum_card.pack_start(hum_title, False, False, 0)
        hum_card.pack_start(hum_val, False, False, 0)
        metrics_box.pack_start(hum_card, True, True, 0)

        # Wind Card
        wind_card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        wind_card.get_style_context().add_class("metrics-card")
        wind_title = Gtk.Label(label="WIND")
        wind_title.get_style_context().add_class("metric-title")
        wind_val = Gtk.Label(label=wind)
        wind_val.get_style_context().add_class("metric-val-wind")
        wind_val.set_ellipsize(3)
        wind_card.pack_start(wind_title, False, False, 0)
        wind_card.pack_start(wind_val, False, False, 0)
        metrics_box.pack_start(wind_card, True, True, 0)

        # UV Card
        uv_card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        uv_card.get_style_context().add_class("metrics-card")
        uv_title = Gtk.Label(label="UV INDEX")
        uv_title.get_style_context().add_class("metric-title")
        uv_val = Gtk.Label(label=str(uv))
        uv_val.get_style_context().add_class("metric-val-uv")
        uv_card.pack_start(uv_title, False, False, 0)
        uv_card.pack_start(uv_val, False, False, 0)
        metrics_box.pack_start(uv_card, True, True, 0)

        self.card.pack_start(metrics_box, False, False, 0)

        # 3-Day Forecast Section
        fc_title = Gtk.Label(label="3-DAY FORECAST")
        fc_title.get_style_context().add_class("section-title")
        fc_title.set_halign(Gtk.Align.START)
        self.card.pack_start(fc_title, False, False, 0)

        fc_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        fc_box.set_homogeneous(True)

        if "weather" in data:
            for i, w in enumerate(data["weather"][:3]):
                try:
                    d_obj = datetime.strptime(w.get("date", ""), "%Y-%m-%d")
                    day_label = "Today" if i == 0 else d_obj.strftime("%a")
                except Exception:
                    day_label = f"Day {i+1}"

                hourly = w.get("hourly", [])
                mid_hour = hourly[4] if len(hourly) > 4 else (hourly[0] if hourly else {})
                f_desc = mid_hour.get("weatherDesc", [{}])[0].get("value", "").strip()
                f_icon = parse_weather_icon(f_desc)
                high = w.get("maxtempF", "--") + "°"
                low = w.get("mintempF", "--") + "°"

                item_card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
                item_card.get_style_context().add_class("forecast-card")

                d_lbl = Gtk.Label(label=day_label)
                d_lbl.get_style_context().add_class("forecast-day-today" if i == 0 else "forecast-day")

                ic_lbl = Gtk.Label(label=f_icon)
                ic_lbl.get_style_context().add_class("forecast-icon")

                t_lbl = Gtk.Label(label=f"{high} / {low}")
                t_lbl.get_style_context().add_class("forecast-temp")

                ds_lbl = Gtk.Label(label=f_desc)
                ds_lbl.get_style_context().add_class("forecast-desc")
                ds_lbl.set_ellipsize(3)

                item_card.pack_start(d_lbl, False, False, 0)
                item_card.pack_start(ic_lbl, False, False, 0)
                item_card.pack_start(t_lbl, False, False, 0)
                item_card.pack_start(ds_lbl, False, False, 0)
                fc_box.pack_start(item_card, True, True, 0)

        self.card.pack_start(fc_box, False, False, 0)
        self.card.show_all()

    def refresh_weather(self):
        def do_refresh():
            try:
                os.remove(CACHE_FILE)
            except Exception:
                pass
            import subprocess
            subprocess.run(["/home/ud/.config/waybar/scripts/weather.py"])
            GLib.idle_add(self.render_content)

        threading.Thread(target=do_refresh, daemon=True).start()

def main():
    win = WeatherMenu()
    win.show_all()
    Gtk.main()

if __name__ == "__main__":
    main()
