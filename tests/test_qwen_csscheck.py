"""csscheck.py: structure slips in CSS text."""
import pathlib
import sys

import pytest

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / ".local" / "share" / "qwen-build"))

from csscheck import css_problem  # noqa: E402

GOOD = [
    "",
    "\n\n",
    "a { color: red; }",
    "a { color: red }",                                   # last declaration needs no ;
    "a{color:red;background:blue}",
    ".a, .b > c:hover::before { margin: 0 auto; }",
    "/* c { */ a { color: red; } /* } */",
    "a { content: '}'; quotes: \"{\" \";\"; }",
    "a { content: 'it\\'s'; }",
    "a { background: url(data:image/png;base64,AAA=) no-repeat; }",
    "a { background: url(http://x/y.png); }",
    "@import url('x.css');\n@charset \"utf-8\";\na { b: c; }",
    "@media (min-width: 600px) { a { color: red; } .b { c: d } }",
    "@keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }",
    "@font-face { font-family: X; src: url(a.woff2) format('woff2'),\n       url(a.woff) format('woff'); }",
    ":root { --main-color: #fff; --empty: ; }".replace("--empty: ;", "--gap: 4px;"),
    ".card { color: red; &:hover { color: blue; } .x & { y: z; } }",     # nesting
    ".btn { @apply px-3 py-1; color: red; }",
    "a { transition: color 1s,\n    background 2s; }",
    "a { grid-template-areas: 'a b'\n    'c d'; }",
    "a[href^='http://'] { color: red; }",
    "a { width: calc(100% - (2 * var(--gap))); }",
    "a { color: red; ; }",
    "a { filter: progid:DXImageTransform.Microsoft.gradient(startColorstr='#1', endColorstr='#2'); }",
    "html { color-scheme: dark; }\n#x { scrollbar-color: #334155 #0f172a; }\n",
]


@pytest.mark.parametrize("text", GOOD)
def test_sound_css_passes(text):
    assert css_problem(text) is None


BAD = [
    ("a { color: red;", "{ is never closed", 1),
    ("a { color: red; } }", "} without a matching {", 1),
    ("a { width: calc(1px + 2px; }", "} closes the ( opened on line 1", 1),
    ("a { color: red; }\n/* open", "comment /* is never closed", 2),
    ("a {\n  content: 'x;\n}", "string ' is never closed", 2),
    ('a { content: "x', 'string " is never closed', 1),
    ("a {\n  color red;\n}", "not a declaration", 2),
    ("a {\n  color: red\n  background: blue;\n}", "missing ; after: color: red", 2),
    ("a {\n  color: red;\n  margin: 0\n  padding: 0\n}", "missing ; after: margin: 0", 3),
    ("{ color: red; }", "block { without a selector", 1),
    ("a { b: c; }\n\n{ d: e; }", "block { without a selector", 3),
    ("color: red;", "; outside any block", 1),
    ("a { b: c; }\nstray words", "text after the last rule: stray words", 2),
    ("a { b: c; }\n```", "text after the last rule", 2),
    ("a { : red; }", "not a declaration", 1),
    ("a { color: ; }", "not a declaration", 1),
    ("@media (min-width: 1px) {\n  a { color: red }\n", "{ is never closed", 1),
    ("a { b: c; ]", "] closes the { opened on line 1", 1),
]


@pytest.mark.parametrize("text,words,line", BAD)
def test_slips_are_reported_with_the_line(text, words, line):
    problem = css_problem(text)
    assert problem is not None, text
    assert words in problem[0]
    assert problem[1] == line


def test_semicolon_and_braces_inside_parens_are_part_of_the_value():
    assert css_problem("a { b: url(x;y{z}); }") is None


def test_comment_lines_keep_line_numbers():
    assert css_problem("/* one\n two\n three */\na {\n  color red;\n}")[1] == 5


def test_message_is_short():
    long = "a { " + "x" * 300 + " }"
    assert len(css_problem(long)[0]) < 120
