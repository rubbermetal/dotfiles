"""
Module to build and play one-line terminal animations using ANSI color escapes.
"""

import re
import time

# Module constants
ICON_OK = ""
ICON_FAIL = ""
ASCII_OK = "[ok]"
ASCII_FAIL = "[x]"
ICONS = {
    "file": "",
    "folder": "",
    "copy": "",
    "trash": "",
    "lock": "",
    "unlock": "",
    "sync": "",
    "download": "",
    "arrow": "",
    "link": "\uf0c1",
    "folder_open": "\uf07c",
    "user": "\uf007",
    "users": "\uf0c0",
    "fire": "\uf06d",
    "eject": "\uf052"
}
GREEN = "\x1b[32m"
RED = "\x1b[31m"
DIM = "\x1b[2m"
STRIKE = "\x1b[9m"
RESET = "\x1b[0m"
STEPS = 8

def shorten(text, room, ascii_only):
    """Shorten text to fit within the given room, adding an ellipsis if necessary."""
    ellipsis = "…" if not ascii_only else "..."
    if len(text) <= room:
        return text
    if room < len(ellipsis):
        return text[:room]
    return text[:room - len(ellipsis)] + ellipsis

def _icon(name, ascii_only):
    """Return the icon for the given name, or an empty string if ascii_only is True."""
    if ascii_only:
        return ""
    return ICONS.get(name, "")

def _arrows(count, ascii_only):
    """Return a string of arrows repeated count times, followed by spaces to make the total length STEPS."""
    arrow = ICONS["arrow"] if not ascii_only else ">"
    return (arrow * count).ljust(STEPS)

def _mark(ok, ascii_only):
    """Return the mark for the given ok status, wrapped in color and reset."""
    if ok:
        return f"{GREEN}{ICON_OK if not ascii_only else ASCII_OK}{RESET}"
    else:
        return f"{RED}{ICON_FAIL if not ascii_only else ASCII_FAIL}{RESET}"

def _who(names):
    """Return a string representing the names."""
    if not names:
        return ""
    if len(names) == 1:
        return names[0]
    return f"{len(names)} files"

_ANSI = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]")
_COMMANDS = ("mv", "cp", "rm", "chmod", "rsync", "curl")


def _visible(text):
    """Length of text as shown on screen (colour escapes take no room)."""
    return len(_ANSI.sub("", text))


def _layout(pieces, ascii_only, budget):
    """Join pieces with spaces. A piece is a string, or a (text, style) tuple for a name that may be shortened.

    The room left after the fixed pieces is shared evenly between the names (at least 3 each).
    """
    pieces = [p for p in pieces if p != ""]
    names = [p for p in pieces if isinstance(p, tuple)]
    used = sum(_visible(p) for p in pieces if isinstance(p, str)) + len(pieces) - 1
    room = max(3, (budget - used) // len(names)) if names else 0
    out = []
    for piece in pieces:
        if isinstance(piece, tuple):
            text, style = piece
            text = shorten(text, room, ascii_only)
            out.append(style + text + RESET if style else text)
        else:
            out.append(piece)
    return " ".join(out)


def build_frames(cmd, info, ok, elapsed, ascii_only=False, width=80):
    """Build the animation frames for a finished command; [] for a command that has none."""
    if cmd not in _COMMANDS:
        from frames_more import build_more      # imported here: frames_more imports this module
        return build_more(cmd, info, ok, elapsed, ascii_only, width)
    a = ascii_only
    budget = width - 1
    who = _who(info.get("sources") or [])
    dest = info.get("dest") or "?"
    mark = _mark(ok, a)
    secs = f"{elapsed:.1f}s"
    frames = []

    def line(*pieces):
        return _layout(list(pieces), a, budget)

    if cmd in ("mv", "cp", "rsync"):
        first = {"mv": "file", "cp": "copy", "rsync": "sync"}[cmd]
        tail = [secs] if cmd == "rsync" else []
        for step in range(1, STEPS + 1):
            frames.append(line(_icon(first, a), (who, ""), _arrows(step, a), _icon("folder", a), (dest, "")))
        frames.append(line(_icon(first, a), (who, ""), _arrows(STEPS, a), _icon("folder", a), (dest, ""), *tail, mark))
    elif cmd == "rm":
        trash = _icon("trash", a)
        for style in ("", "", STRIKE, STRIKE, DIM + STRIKE):
            frames.append(line(trash, (who, style)))
        frames.append(line(trash, (who, STRIKE), mark))
    elif cmd == "chmod":
        mode = info.get("mode") or "ref"
        for step in range(1, STEPS + 1):
            icon = _icon("lock" if step % 2 else "unlock", a)
            frames.append(line(icon, (who, ""), mode))
        frames.append(line(_icon("unlock", a), (who, ""), mode, mark))
    else:  # curl
        url = info.get("url") or "?"
        output = info.get("output") or "stdout"
        for step in range(1, STEPS + 1):
            frames.append(line(_icon("download", a), (url, ""), _arrows(step, a), _icon("file", a), (output, "")))
        frames.append(line(_icon("download", a), (url, ""), _arrows(STEPS, a), _icon("file", a), (output, ""), secs, mark))
    return frames


def play(frames, out, delay):
    """Play the given frames on the output with the specified delay."""
    if not frames:
        return

    for frame in frames:
        out.write("\r\x1b[2K" + frame)
        out.flush()
        if delay > 0:
            time.sleep(delay)

    out.write("\n")
    out.flush()
