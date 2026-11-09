"""
Module to build and play one-line terminal animations for ten shell functions using ANSI color escapes.

Usage example:
    from frames_funcs import parse_result, build_result
    info = parse_result("trash", ["file1", "file2"])
    frames = build_result("trash", info, True)
    for frame in frames:
        print(frame)
"""

from frames import _layout, _icon, _arrows, _mark, _who, STEPS

NAMES = ("trash", "trashempty", "extract", "mkcd", "mvg", "cpg", "chmodfix", "chmodcopy", "chmoddirs", "chmodfiles")

def parse_result(name, args):
    """Return a dict with exactly the keys "sources" (list of str), "dest" (str or None), "mode" (str or None)."""
    info = {"sources": [], "dest": None, "mode": None}
    
    if name == "trash":
        info["sources"] = [arg for arg in args if not arg.startswith("-")]
    elif name == "trashempty":
        pass
    elif name == "extract":
        if args:
            info["sources"] = [args[0]]
            info["dest"] = args[1] if len(args) > 1 else "."
    elif name == "mkcd":
        info["sources"] = list(args)
    elif name in ("mvg", "cpg"):
        if len(args) >= 2:
            info["sources"] = args[:-1]
            info["dest"] = args[-1]
    elif name == "chmodfix":
        info["sources"] = [args[0]] if args else ["."]
    elif name == "chmodcopy":
        if len(args) >= 2:
            info["mode"] = args[0]
            info["sources"] = args[1:]
    elif name in ("chmoddirs", "chmodfiles"):
        rest = [arg for arg in args if arg not in ("-y", "--yes")]
        if rest:
            info["mode"] = rest[0]
            info["sources"] = rest[1:] or ["."]
    else:
        pass
    
    return info

def _pieces(name, info, step, ascii_only):
    """Return the list of pieces for exactly one name, with no other pieces added."""
    a = ascii_only
    who = _who(info["sources"])
    dest = info["dest"]
    mode = info["mode"]
    
    if name in ("trash", "trashempty"):
        if name == "trashempty":
            who = "Trash"
        return [_icon("trash", a), (who, ""), _arrows(step, a)]
    elif name == "extract":
        return [_icon("folder_open", a), (who, ""), _arrows(step, a), (dest, "")]
    elif name == "mkcd":
        return [_icon("folder_open", a), (who, ""), _arrows(step, a)]
    elif name == "mvg":
        return [_icon("file", a), (who, ""), _arrows(step, a), (dest, "")]
    elif name == "cpg":
        return [_icon("copy", a), (who, ""), _arrows(step, a), (dest, "")]
    elif name == "chmodfix":
        return [_icon("lock", a), (who, ""), _arrows(step, a)]
    elif name in ("chmodcopy", "chmoddirs", "chmodfiles"):
        return [_icon("lock", a), (mode, ""), _arrows(step, a), (who, "")]
    else:
        return []

def build_result(name, info, ok, ascii_only=False, width=80):
    """Return a list of frame strings."""
    if name not in NAMES or (name != "trashempty" and not info["sources"]):
        return []
    
    a = ascii_only
    budget = width - 1
    frames = [_layout(_pieces(name, info, step, a), a, budget) for step in range(1, STEPS + 1)]
    final_frame = _layout(_pieces(name, info, STEPS, a) + [_mark(ok, a)], a, budget)
    frames.append(final_frame)
    
    return frames
