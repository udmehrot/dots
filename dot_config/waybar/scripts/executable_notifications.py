#!/usr/bin/env python3
import json
import subprocess
import sys

def main():
    proc = subprocess.Popen(
        ["swaync-client", "-swb"],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True
    )

    for line in proc.stdout:
        line = line.strip()
        if not line:
            continue
        try:
            data = json.loads(line)
        except Exception:
            continue

        raw_count = data.get("text", "0")
        try:
            count = int(raw_count)
        except ValueError:
            count = 0

        alt = data.get("alt", "none")
        is_dnd = "dnd" in alt

        if is_dnd:
            if count > 0:
                text = f"<span color='#eb6f92'>󰂛</span> <span foreground='#191724' background='#eb6f92' weight='bold'> {count} </span>"
            else:
                text = "<span color='#eb6f92'>󰂛</span> <span color='#eb6f92' weight='medium'>DND</span>"
        else:
            if count > 0:
                text = f"<span color='#ebbcba'>󰂚</span> <span foreground='#191724' background='#ebbcba' weight='bold'> {count} </span>"
            else:
                text = "<span color='#908caa'>󰂜</span>"

        tooltip = f"{count} Notification{'s' if count != 1 else ''}"
        if is_dnd:
            tooltip += " (Do Not Disturb)"

        out = {
            "text": text,
            "alt": alt,
            "tooltip": tooltip,
            "class": alt
        }
        print(json.dumps(out), flush=True)

if __name__ == "__main__":
    main()
