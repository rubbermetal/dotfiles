"""
anim is a command-line runner that animates certain commands.

Usage example:
    anim mv -vi report.txt ~/docs/
"""

import os
import sys
import time
import shutil
import subprocess
from operands import parse_operands
from frames import build_frames, play

ANIMATED = {"mv", "cp", "rm", "chmod", "rsync", "curl", "ln", "mkdir", "chown", "chgrp", "shred", "wget", "umount"}

def _ascii_only():
    anim_ascii = os.environ.get("ANIM_ASCII", "")
    term = os.environ.get("TERM", "")
    encoding = (sys.stdout.encoding or "").replace("-", "").lower()
    return anim_ascii not in ("", "0") or term in ("linux", "dumb") or encoding != "utf8"

def _delay():
    try:
        return float(os.environ.get("ANIM_DELAY", "0.03"))
    except ValueError:
        return 0.03

def _should_animate(cmd):
    return (os.path.basename(cmd) in ANIMATED and
            sys.stdout.isatty() and
            os.environ.get("ANIM", "1") != "0")

def main(argv=None):
    if argv is None:
        argv = sys.argv[1:]

    if not argv:
        print("usage: anim COMMAND [ARGS...]", file=sys.stderr)
        return 2

    cmd = argv[0]
    start = time.monotonic()

    try:
        completed = subprocess.run(argv, check=False)
    except FileNotFoundError:
        print(f"anim: {cmd}: command not found", file=sys.stderr)
        return 127
    except PermissionError:
        print(f"anim: {cmd}: permission denied", file=sys.stderr)
        return 126
    except KeyboardInterrupt:
        return 130

    rc = completed.returncode
    if rc < 0:
        rc = 128 - rc

    elapsed = time.monotonic() - start

    if _should_animate(cmd):
        name = os.path.basename(cmd)
        info = parse_operands(name, argv[1:])
        width = shutil.get_terminal_size((80, 24)).columns
        frames = build_frames(name, info, rc == 0, elapsed, ascii_only=_ascii_only(), width=width)
        play(frames, sys.stdout, _delay())

    return rc
