"""
Module for finding, extracting, and splicing sections of text based on regular expressions.

Usage example:
    first, last = find_section(text, r"function syncSideAxis\\(")
    body, indent = extract(text, first, last)
    text = splice(text, first, last, new_body, indent)
"""

import re
import os

class SectionError(ValueError):
    """Error raised for issues with section operations."""

def _lines(text):
    """Helper function to split text into lines as defined."""
    parts = text.split("\n")
    if parts and parts[-1] == "":
        parts.pop()
    return parts

def find_section(text, start, end=None):
    """Find the first and last line numbers of a section in text."""
    lines = _lines(text)
    start_matches = [i + 1 for i, line in enumerate(lines) if re.search(start, line)]
    
    if len(start_matches) == 0:
        raise SectionError(f"no line matches {repr(start)}")
    if len(start_matches) > 1:
        raise SectionError(f"{len(start_matches)} lines match {repr(start)}")
    
    first = start_matches[0]
    
    if end is not None:
        for i in range(first, len(lines)):
            if re.search(end, lines[i]):
                return first, i + 1
        raise SectionError(f"no line after the start matches {repr(end)}")
    
    # Brace mode
    depth = 0
    opened = False
    for i in range(first - 1, len(lines)):
        line = lines[i]
        for char in line:
            if char == "{":
                depth += 1
                opened = True
            elif char == "}":
                depth -= 1
        if opened and depth <= 0:
            return first, i + 1
    
    raise SectionError("no balanced { } block after the start line")

def extract(text, first, last):
    """Extract a section of text and return the body and indentation."""
    lines = _lines(text)
    n = len(lines)
    
    if not (1 <= first <= last <= n):
        raise SectionError("bad line range")
    
    chosen = lines[first - 1:last]
    # The indent must be known for the whole range before any line is cut.
    leads = [line[:len(line) - len(line.lstrip(" \t"))] for line in chosen if line.strip() != ""]
    indent = os.path.commonprefix(leads) if leads else ""
    body_lines = ["" if line.strip() == "" else line[len(indent):] for line in chosen]
    return "\n".join(body_lines) + "\n", indent

def splice(text, first, last, body, indent):
    """Splice a new body back into the text at the specified range."""
    lines = _lines(text)
    n = len(lines)
    
    if not (1 <= first <= last <= n):
        raise SectionError("bad line range")
    
    new_lines = body.rstrip("\n").split("\n")
    if body.strip() == "":
        raise SectionError("empty body")
    
    new_lines = [indent + line if line.strip() != "" else "" for line in new_lines]
    
    parts = text.split("\n")
    parts[first - 1:last] = new_lines
    return "\n".join(parts)
