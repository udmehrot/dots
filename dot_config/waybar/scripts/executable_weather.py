#!/usr/bin/env python3
import json
import os
import sys
import time
import urllib.request
import urllib.error
from datetime import datetime

CACHE_FILE = "/tmp/waybar_weather_cache.json"
CACHE_TTL = 900  # 15 minutes

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

def fetch_weather():
    url = "https://wttr.in/?format=j1"
    req = urllib.request.Request(url, headers={"User-Agent": "curl/8.0"})
    with urllib.request.urlopen(req, timeout=6) as resp:
        return json.loads(resp.read().decode("utf-8"))

def get_data():
    now = time.time()
    if os.path.exists(CACHE_FILE):
        try:
            mtime = os.path.getmtime(CACHE_FILE)
            if now - mtime < CACHE_TTL:
                with open(CACHE_FILE, "r") as f:
                    return json.load(f)
        except Exception:
            pass

    try:
        data = fetch_weather()
        with open(CACHE_FILE, "w") as f:
            json.dump(data, f)
        return data
    except Exception:
        if os.path.exists(CACHE_FILE):
            try:
                with open(CACHE_FILE, "r") as f:
                    return json.load(f)
            except Exception:
                pass
        return None

def main():
    data = get_data()
    if not data or "current_condition" not in data or not data["current_condition"]:
        print(json.dumps({
            "text": "<span color='#f6c177'>󰖐</span> --°",
            "tooltip": "Weather unavailable",
            "class": "weather"
        }))
        return

    curr = data["current_condition"][0]
    desc = curr.get("weatherDesc", [{}])[0].get("value", "").strip()
    temp_f = curr.get("temp_F", "--")
    feels_like_f = curr.get("FeelsLikeF", "--")
    humidity = curr.get("humidity", "--")
    wind = f"{curr.get('windspeedMiles', '--')} mph {curr.get('winddir16Point', '')}".strip()
    uv = curr.get("uvIndex", "--")
    icon = parse_weather_icon(desc)

    loc = "Unknown Location"
    if "nearest_area" in data and data["nearest_area"]:
        area = data["nearest_area"][0]
        area_name = area.get("areaName", [{}])[0].get("value", "")
        region = area.get("region", [{}])[0].get("value", "")
        loc = f"{area_name}, {region}" if region else area_name

    tooltip_lines = [
        f"<b>{loc}</b>",
        f"{desc} • Feels like {feels_like_f}°F",
        f"Humidity: {humidity}% | Wind: {wind} | UV: {uv}",
        "",
        "<b>3-Day Forecast:</b>"
    ]

    days_of_week = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    if "weather" in data:
        for i, w in enumerate(data["weather"][:3]):
            try:
                d_obj = datetime.strptime(w.get("date", ""), "%Y-%m-%d")
                day_label = "Today" if i == 0 else days_of_week[d_obj.weekday() if d_obj.weekday() < 6 else 6]
                # Note: Python weekday() Monday is 0, Sunday is 6
                # Let's use d_obj.strftime("%a") for safety:
                day_label = "Today" if i == 0 else d_obj.strftime("%a")
            except Exception:
                day_label = f"Day {i+1}"

            hourly = w.get("hourly", [])
            mid_hour = hourly[4] if len(hourly) > 4 else (hourly[0] if hourly else {})
            f_desc = mid_hour.get("weatherDesc", [{}])[0].get("value", "").strip()
            f_icon = parse_weather_icon(f_desc)
            high = w.get("maxtempF", "--") + "°"
            low = w.get("mintempF", "--") + "°"
            tooltip_lines.append(f"{day_label:5} {f_icon} {high}/{low} - {f_desc}")

    text = f"<span color='#f6c177'>{icon}</span> {temp_f}°F"

    print(json.dumps({
        "text": text,
        "tooltip": "",
        "class": "weather"
    }), flush=True)

if __name__ == "__main__":
    main()
