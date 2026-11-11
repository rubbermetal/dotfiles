"""
A small structure check for CSS text: finds the slips a model makes, not style problems.

Usage example:
    problem = css_problem(text)      # None, or (message, line) with a 1-based line number
    if problem: print(f"CSS error: {problem[0]} at line {problem[1]}")

It reports: an unclosed comment or string, brackets that do not pair up, a block without a
selector, text in a block that is not `property: value` (a missing colon), a missing
semicolon between two declarations, a `;` statement outside any block that is not an
at-rule, and text left over after the last rule. It knows nothing about which properties
or values exist. Nested rules (CSS nesting, @media, @keyframes) are followed.
"""

import re

_DECL = re.compile(r"^[-\w]+\s*:\s*\S", re.S)            # property: value   (also --custom: x)
_NEXT_DECL = re.compile(r"\n\s*[-\w]+\s*:(?!:)\s*\S")     # a second declaration on a later line
_PAIRS = {")": "(", "]": "[", "}": "{"}


def _strip(text):
    """text with comments and string contents blanked (newlines kept), or (message, line)."""
    out = []
    i, n, line = 0, len(text), 1
    while i < n:
        c = text[i]
        if c == "/" and text[i:i + 2] == "/*":
            end = text.find("*/", i + 2)
            if end == -1:
                return "comment /* is never closed", line
            chunk = text[i:end + 2]
            out.append("".join("\n" if ch == "\n" else " " for ch in chunk))
            line += chunk.count("\n")
            i = end + 2
        elif c in "'\"":
            start_line = line
            j = i + 1
            while j < n and text[j] != c:
                if text[j] == "\\" and j + 1 < n:
                    if text[j + 1] == "\n":
                        line += 1
                    j += 2
                    continue
                if text[j] == "\n":
                    return f"string {c} is never closed", start_line
                j += 1
            if j >= n:
                return f"string {c} is never closed", start_line
            body = text[i + 1:j]
            out.append(c + "".join("\n" if ch == "\n" else "s" for ch in body) + c)
            i = j + 1
        else:
            if c == "\n":
                line += 1
            out.append(c)
            i += 1
    return "".join(out)


def _declaration(stmt, line):
    """Problem for one statement inside a block, or None."""
    text = stmt.strip()
    if text == "" or text.startswith("@"):
        return None
    first_line = line                                   # line of the statement's first character
    shown = " ".join(text.split())[:60]
    if not _DECL.match(text):
        return f"not a declaration (expected property: value;): {shown}", first_line
    m = _NEXT_DECL.search(text)
    if m:
        missing_after = " ".join(text[:m.start()].split())[:60]
        return f"missing ; after: {missing_after}", first_line + text[:m.start()].count("\n")
    return None


def css_problem(text):
    """None when the CSS is structurally sound, else (message, line)."""
    clean = _strip(text)
    if isinstance(clean, tuple):
        return clean

    stack = []                     # (opening char, line)
    blocks = 0                     # depth of { }
    parens = 0                     # depth of ( ) and [ ]
    stmt, stmt_line, line = "", 1, 1
    for c in clean:
        if c in "([{":
            stack.append((c, line))
        elif c in ")]}":
            if not stack:
                return f"{c} without a matching {_PAIRS[c]}", line
            opener, opened_line = stack.pop()
            if opener != _PAIRS[c]:
                return f"{c} closes the {opener} opened on line {opened_line}", line

        if c in "([":
            parens += 1
            stmt += c
        elif c in ")]":
            parens -= 1
            stmt += c
        elif parens > 0:
            stmt += c                                    # ; { } inside ( ) are part of a value
        elif c == "{":
            if stmt.strip() == "":
                return "block { without a selector before it", line
            blocks += 1
            stmt, stmt_line = "", line
        elif c == "}":
            problem = _declaration(stmt, stmt_line)      # the last declaration needs no ;
            if problem:
                return problem
            blocks -= 1
            stmt, stmt_line = "", line
        elif c == ";":
            if blocks == 0:
                if stmt.strip() and not stmt.strip().startswith("@"):
                    return "; outside any block: " + " ".join(stmt.split())[:60], line
            else:
                problem = _declaration(stmt, stmt_line)
                if problem:
                    return problem
            stmt, stmt_line = "", line
        else:
            if stmt.strip() == "" and not c.isspace():
                stmt_line = line
            stmt += c
        if c == "\n":
            line += 1

    if stack:
        opener, opened_line = stack[-1]
        return f"{opener} is never closed", opened_line
    if stmt.strip():
        return "text after the last rule: " + " ".join(stmt.split())[:60], stmt_line
    return None
