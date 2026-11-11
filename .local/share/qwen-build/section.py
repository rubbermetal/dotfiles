"""
Find a block of lines in a big text file, pull it out with its indentation removed,
and put a rewritten block back with the indentation restored.

Usage example:
    first, last = find_section(text, r"function syncSideAxis\\(")   # or find_def(text, "build")
    body, indent = extract(text, first, last)
    text = splice(text, first, last, new_body, indent)

Line numbers are 1-based and inclusive. Only "\\n" line endings are handled.
"""

import ast
import os
import re


class SectionError(ValueError):
    """Error raised for issues with section operations."""


def _lines(text):
    """Lines of text; a final newline does not start another line."""
    parts = text.split("\n")
    if parts and parts[-1] == "":
        parts.pop()
    return parts


def _braces(text):
    """Yield (line_index, char) for every { and } outside strings and comments.

    Understands '..' and ".." (end at the end of the line at the latest), `..` (may span
    lines), // line comments and /* */ block comments. line_index is 0-based in text.
    """
    state = None            # None, a quote character, "//" or "/*"
    line = 0
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        nxt = text[i + 1] if i + 1 < n else ""
        if c == "\n":
            line += 1
            if state in ("'", '"', "//"):
                state = None
        elif state is None:
            if c == "/" and nxt == "/":
                state = "//"
                i += 1
            elif c == "/" and nxt == "*":
                state = "/*"
                i += 1
            elif c in "'\"`":
                state = c
            elif c in "{}":
                yield line, c
        elif state == "/*":
            if c == "*" and nxt == "/":
                state = None
                i += 1
        elif state != "//":                     # inside a string
            if c == "\\":
                if nxt != "\n":                 # never jump over a line end
                    i += 1
            elif c == state:
                state = None
        i += 1


def brace_counts(text):
    """(number of {, number of }) outside strings and comments."""
    opens = closes = 0
    for _, c in _braces(text):
        if c == "{":
            opens += 1
        else:
            closes += 1
    return opens, closes


def find_section(text, start, end=None):
    """(first, last) of the section whose first line is the ONE line matching start.

    With end: runs to the first later line matching end. Without: to the line where the
    { } block opened at or after the start line closes (strings and comments ignored).
    """
    lines = _lines(text)
    start_matches = [i + 1 for i, line in enumerate(lines) if re.search(start, line)]
    if len(start_matches) == 0:
        raise SectionError(f"no line matches {start!r}")
    if len(start_matches) > 1:
        raise SectionError(f"{len(start_matches)} lines match {start!r}")
    first = start_matches[0]

    if end is not None:
        for i in range(first, len(lines)):
            if re.search(end, lines[i]):
                return first, i + 1
        raise SectionError(f"no line after the start matches {end!r}")

    depth = 0
    events = list(_braces("\n".join(lines[first - 1:])))
    for k, (offset, c) in enumerate(events):
        depth += 1 if c == "{" else -1
        # The block is closed at the end of a line, so wait for the line's last brace.
        last_on_line = k + 1 == len(events) or events[k + 1][0] != offset
        if last_on_line and depth <= 0:
            return first, first + offset
    raise SectionError("no balanced { } block after the start line")


def find_def(text, name):
    """(first, last) of a Python function or class, decorators included.

    name is a bare name ("build") or a dotted path ("Reader.parse", "outer.inner").
    """
    try:
        tree = ast.parse(text)
    except SyntaxError as exc:
        raise SectionError(f"cannot parse the file as Python: {exc.msg} (line {exc.lineno})")
    kinds = (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)
    found = []

    def walk(node, prefix):
        for child in ast.iter_child_nodes(node):
            if isinstance(child, kinds):
                path = prefix + child.name
                if path == name or ("." not in name and child.name == name):
                    found.append((path, child))
                walk(child, path + ".")
            else:
                walk(child, prefix)

    walk(tree, "")
    if not found:
        raise SectionError(f"no def or class named {name!r}")
    if len(found) > 1:
        raise SectionError(f"{len(found)} defs match {name!r}: " + ", ".join(p for p, _ in found) + " (give the dotted name)")
    node = found[0][1]
    first = min([node.lineno] + [d.lineno for d in node.decorator_list])
    return first, node.end_lineno


def extract(text, first, last):
    """(body, indent): lines first..last with their common indentation removed."""
    lines = _lines(text)
    if not (1 <= first <= last <= len(lines)):
        raise SectionError("bad line range")
    chosen = lines[first - 1:last]
    # The indent must be known for the whole range before any line is cut.
    leads = [line[:len(line) - len(line.lstrip(" \t"))] for line in chosen if line.strip() != ""]
    indent = os.path.commonprefix(leads) if leads else ""
    body_lines = ["" if line.strip() == "" else line[len(indent):] for line in chosen]
    return "\n".join(body_lines) + "\n", indent


def splice(text, first, last, body, indent):
    """text with lines first..last replaced by body, re-indented; the rest untouched."""
    if not (1 <= first <= last <= len(_lines(text))):
        raise SectionError("bad line range")
    if body.strip() == "":
        raise SectionError("empty body")
    new_lines = [indent + line if line.strip() != "" else "" for line in body.rstrip("\n").split("\n")]
    parts = text.split("\n")
    parts[first - 1:last] = new_lines
    return "\n".join(parts)
