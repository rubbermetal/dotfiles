"""
Module to build and play one-line terminal animations for additional commands using ANSI color escapes.
"""

from frames import _layout, _icon, _arrows, _mark, _who, STEPS, STRIKE, DIM

def build_more(cmd, info, ok, elapsed, ascii_only, width):
    """Build the animation frames for additional commands: ln, mkdir, chown, chgrp, shred, wget, umount."""
    if cmd not in ("ln", "mkdir", "chown", "chgrp", "shred", "wget", "umount"):
        return []

    a = ascii_only
    budget = width - 1
    who = _who(info.get("sources") or [])
    dest = info.get("dest") or "?"
    mark = _mark(ok, a)
    secs = f"{elapsed:.1f}s" if cmd == "wget" else ""
    frames = []

    def line(*pieces):
        return _layout(list(pieces), a, budget)

    if cmd == "ln":
        for step in range(1, STEPS + 1):
            frames.append(line(_icon("link", a), (who, ""), _arrows(step, a), _icon("file", a), (dest, "")))
        frames.append(line(_icon("link", a), (who, ""), _arrows(STEPS, a), _icon("file", a), (dest, ""), mark))
    elif cmd == "mkdir":
        for step in range(1, STEPS + 1):
            frames.append(line(_icon("folder_open", a), (who, ""), _arrows(step, a)))
        frames.append(line(_icon("folder_open", a), (who, ""), _arrows(STEPS, a), mark))
    elif cmd == "chown":
        for step in range(1, STEPS + 1):
            frames.append(line(_icon("user", a), (info.get("mode") or "ref", ""), _arrows(step, a), _icon("file", a), (who, "")))
        frames.append(line(_icon("user", a), (info.get("mode") or "ref", ""), _arrows(STEPS, a), _icon("file", a), (who, ""), mark))
    elif cmd == "chgrp":
        for step in range(1, STEPS + 1):
            frames.append(line(_icon("users", a), (info.get("mode") or "ref", ""), _arrows(step, a), _icon("file", a), (who, "")))
        frames.append(line(_icon("users", a), (info.get("mode") or "ref", ""), _arrows(STEPS, a), _icon("file", a), (who, ""), mark))
    elif cmd == "shred":
        for step in range(1, 7):
            if step <= 2:
                frames.append(line(_icon("fire", a), (who, "")))
            elif step <= 4:
                frames.append(line(_icon("fire", a), (who, STRIKE)))
            elif step == 5:
                frames.append(line(_icon("fire", a), (who, DIM + STRIKE)))
            else:
                frames.append(line(_icon("fire", a), (who, STRIKE), mark))
    elif cmd == "wget":
        for step in range(1, STEPS + 1):
            frames.append(line(_icon("download", a), (info.get("url") or "?", ""), _arrows(step, a), _icon("file", a), (info.get("output") or "stdout", "")))
        frames.append(line(_icon("download", a), (info.get("url") or "?", ""), _arrows(STEPS, a), _icon("file", a), (info.get("output") or "stdout", ""), secs, mark))
    elif cmd == "umount":
        for step in range(1, STEPS + 1):
            frames.append(line(_icon("eject", a), (who, ""), _arrows(step, a)))
        frames.append(line(_icon("eject", a), (who, ""), _arrows(STEPS, a), mark))

    return frames
