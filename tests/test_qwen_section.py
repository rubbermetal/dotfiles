"""section.py: find a block in a big file, pull it out, put a rewritten one back."""
import pathlib
import sys

import pytest

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / ".local" / "share" / "qwen-build"))

import section  # noqa: E402
from section import SectionError, brace_counts, extract, find_def, find_section, hoist_imports, splice  # noqa: E402

PAGE = (
    "<html>\n"                                  # 1
    "<script>\n"                                # 2
    "    function alpha(a) {\n"                 # 3
    "        if (a) {\n"                        # 4
    "            return 1;\n"                   # 5
    "        }\n"                               # 6
    "\n"                                        # 7
    "        return 0;\n"                       # 8
    "    }\n"                                   # 9
    "\n"                                        # 10
    "    function beta() { return 2; }\n"       # 11
    "    // BEGIN colors\n"                     # 12
    "    const C = 1;\n"                        # 13
    "    // END colors\n"                       # 14
    "</script>\n"                               # 15
    "</html>\n"                                 # 16
)


# ---- find_section ---------------------------------------------------------- #

def test_section_error_is_a_value_error():
    assert issubclass(SectionError, ValueError)


def test_find_brace_block():
    assert find_section(PAGE, r"function alpha\(") == (3, 9)


def test_find_brace_block_on_one_line():
    assert find_section(PAGE, r"function beta\(") == (11, 11)


def test_find_brace_block_opening_on_a_later_line():
    text = "def\nfoo()\n{\n  x;\n}\nrest\n"
    assert find_section(text, r"^foo") == (2, 5)


def test_find_with_end_pattern():
    assert find_section(PAGE, r"BEGIN colors", r"END colors") == (12, 14)


def test_end_pattern_is_searched_after_the_start_line_only():
    text = "x MARK x\nbody\nx MARK x\n"
    with pytest.raises(SectionError):
        find_section(text, r"MARK")            # two start matches
    text = "START MARK\nbody\nMARK\n"
    assert find_section(text, r"START", r"MARK") == (1, 3)


def test_start_is_a_regex_search_not_a_full_match():
    assert find_section(PAGE, r"alpha") == (3, 9)


def test_no_start_match():
    with pytest.raises(SectionError) as e:
        find_section(PAGE, r"function gamma")
    assert "no line matches" in str(e.value)


def test_several_start_matches():
    with pytest.raises(SectionError) as e:
        find_section(PAGE, r"function ")
    assert "2 lines match" in str(e.value)


def test_end_pattern_never_matches():
    with pytest.raises(SectionError):
        find_section(PAGE, r"BEGIN colors", r"NEVER")


def test_brace_never_opens():
    with pytest.raises(SectionError):
        find_section("a\nb\nc\n", r"^b$")


def test_brace_never_closes():
    with pytest.raises(SectionError):
        find_section("f() {\n  x;\n", r"f\(")


def test_file_without_final_newline():
    assert find_section("a {\n}", r"^a") == (1, 2)


# ---- extract --------------------------------------------------------------- #

def test_extract_dedents_and_reports_the_indent():
    body, indent = extract(PAGE, 3, 9)
    assert indent == "    "
    assert body == (
        "function alpha(a) {\n"
        "    if (a) {\n"
        "        return 1;\n"
        "    }\n"
        "\n"
        "    return 0;\n"
        "}\n"
    )


def test_extract_no_indent():
    assert extract(PAGE, 1, 2) == ("<html>\n<script>\n", "")


def test_extract_single_line():
    assert extract(PAGE, 13, 13) == ("const C = 1;\n", "    ")


def test_extract_tab_indent():
    assert extract("\tif x:\n\t\ty\n", 1, 2) == ("if x:\n\ty\n", "\t")


def test_extract_blank_lines_do_not_count_for_the_indent():
    text = "    a\n\n  \n    b\n"
    assert extract(text, 1, 4) == ("a\n\n\nb\n", "    ")


def test_extract_last_line_without_final_newline():
    assert extract("x\n  y", 2, 2) == ("y\n", "  ")


@pytest.mark.parametrize("first,last", [(0, 2), (3, 2), (1, 17), (17, 17), (-1, 1)])
def test_extract_bad_range(first, last):
    with pytest.raises(SectionError):
        extract(PAGE, first, last)


def test_extract_empty_text():
    with pytest.raises(SectionError):
        extract("", 1, 1)


# ---- splice ---------------------------------------------------------------- #

def test_round_trip_changes_nothing():
    for first, last in [(3, 9), (11, 11), (12, 14), (1, 16), (16, 16)]:
        body, indent = extract(PAGE, first, last)
        assert splice(PAGE, first, last, body, indent) == PAGE


def test_splice_reindents_the_new_body():
    new = "function alpha(a) {\n    return 5;\n}\n"
    out = splice(PAGE, 3, 9, new, "    ")
    lines = out.split("\n")
    assert lines[1] == "<script>"
    assert lines[2:5] == ["    function alpha(a) {", "        return 5;", "    }"]
    assert lines[5] == ""                                  # old line 10
    assert lines[6] == "    function beta() { return 2; }"
    assert out.endswith("</html>\n")
    assert len(lines) == len(PAGE.split("\n")) - 4


def test_splice_blank_lines_get_no_indent():
    out = splice("    a\n    b\n", 1, 2, "x\n\ny\n", "    ")
    assert out == "    x\n\n    y\n"


def test_splice_body_trailing_newlines_do_not_add_lines():
    assert splice("a\nb\nc\n", 2, 2, "B\n\n\n", "") == "a\nB\nc\n"
    assert splice("a\nb\nc\n", 2, 2, "B", "") == "a\nB\nc\n"


def test_splice_body_can_grow():
    assert splice("a\nb\nc\n", 2, 2, "1\n2\n3\n", "  ") == "a\n  1\n  2\n  3\nc\n"


def test_splice_keeps_missing_final_newline():
    assert splice("a\n  b", 2, 2, "z\n", "  ") == "a\n  z"


def test_splice_keeps_final_newline():
    assert splice("a\n  b\n", 2, 2, "z", "  ") == "a\n  z\n"


def test_splice_first_and_last_lines():
    assert splice("a\nb\nc\n", 1, 1, "A\n", "") == "A\nb\nc\n"
    assert splice("a\nb\nc\n", 3, 3, "C\n", "") == "a\nb\nC\n"
    assert splice("a\nb\nc\n", 1, 3, "only\n", "") == "only\n"


def test_splice_bad_range():
    with pytest.raises(SectionError):
        splice("a\nb\n", 2, 3, "x\n", "")
    with pytest.raises(SectionError):
        splice("a\nb\n", 0, 1, "x\n", "")


def test_splice_empty_body_is_an_error():
    with pytest.raises(SectionError):
        splice("a\nb\n", 1, 1, "", "")
    with pytest.raises(SectionError):
        splice("a\nb\n", 1, 1, "\n\n", "")


# ---- braces inside strings and comments ------------------------------------ #

def test_brace_counts_plain():
    assert brace_counts("a { b { } }") == (2, 2)
    assert brace_counts("") == (0, 0)


@pytest.mark.parametrize("text", [
    "x = '}';",
    'x = "{{{";',
    "x = `}\n}`;",
    "// } } }",
    "/* {\n { */",
    "x = 'it\\'s }';",
    'x = "a \\" }";',
])
def test_brace_counts_ignores_strings_and_comments(text):
    assert brace_counts(text) == (0, 0)


def test_quote_ends_at_the_line_end():
    # an apostrophe in prose must not hide the braces of later lines
    assert brace_counts("don't\n{ }\n") == (1, 1)
    assert brace_counts("x = 'abc\\\n{ }\n") == (1, 1)


def test_comment_markers_inside_strings_are_text():
    assert brace_counts("u = 'http://x'; f() { }") == (1, 1)
    assert brace_counts('u = "/* x"; f() { }') == (1, 1)


def test_find_ignores_a_closing_brace_in_a_string():
    text = "function f() {\n    const s = '}';\n    return s; // }\n}\nafter();\n"
    assert find_section(text, r"function f") == (1, 4)


def test_find_ignores_an_opening_brace_in_a_comment():
    text = "function f() {\n    /* { */\n    return `${a} {`;\n}\nafter();\n"
    assert find_section(text, r"function f") == (1, 4)


def test_find_else_on_the_closing_line_keeps_going():
    text = "if (a) {\n  x;\n} else {\n  y;\n}\nz;\n"
    assert find_section(text, r"^if") == (1, 5)


# ---- find_def (Python) ----------------------------------------------------- #

PY = (
    "import os\n"                       # 1
    "\n"                                # 2
    "\n"                                # 3
    "@decorator\n"                      # 4
    "@other(1)\n"                       # 5
    "def build(\n"                      # 6
    "    a,\n"                          # 7
    "    b=2,\n"                        # 8
    "):\n"                              # 9
    "    x = {\n"                       # 10
    "        'k': 1,\n"                 # 11
    "    }\n"                           # 12
    "\n"                                # 13
    "    return x\n"                    # 14
    "\n"                                # 15
    "\n"                                # 16
    "class Reader:\n"                   # 17
    "    def parse(self):\n"            # 18
    "        return 1\n"                # 19
    "\n"                                # 20
    "    async def load(self):\n"       # 21
    "        def inner():\n"            # 22
    "            return 2\n"            # 23
    "        return inner\n"            # 24
    "\n"                                # 25
    "\n"                                # 26
    "class Writer:\n"                   # 27
    "    def parse(self):\n"            # 28
    "        return 3\n"                # 29
)


def test_find_def_function_with_decorators_and_multiline_signature():
    assert find_def(PY, "build") == (4, 14)


def test_find_def_class():
    assert find_def(PY, "Reader") == (17, 24)
    assert find_def(PY, "Writer") == (27, 29)


def test_find_def_method_by_dotted_name():
    assert find_def(PY, "Reader.parse") == (18, 19)
    assert find_def(PY, "Writer.parse") == (28, 29)


def test_find_def_async_and_nested():
    assert find_def(PY, "load") == (21, 24)
    assert find_def(PY, "inner") == (22, 23)
    assert find_def(PY, "Reader.load.inner") == (22, 23)


def test_find_def_ambiguous_bare_name():
    with pytest.raises(SectionError) as e:
        find_def(PY, "parse")
    assert "2 defs match" in str(e.value)
    assert "Reader.parse" in str(e.value) and "Writer.parse" in str(e.value)


def test_find_def_missing():
    with pytest.raises(SectionError) as e:
        find_def(PY, "nope")
    assert "no def or class named" in str(e.value)
    with pytest.raises(SectionError):
        find_def(PY, "Reader.nope")


def test_find_def_unparsable_file():
    with pytest.raises(SectionError) as e:
        find_def("def f(:\n", "f")
    assert "cannot parse" in str(e.value)


def test_find_def_round_trip():
    first, last = find_def(PY, "Reader.parse")
    body, indent = extract(PY, first, last)
    assert (body, indent) == ("def parse(self):\n    return 1\n", "    ")
    assert splice(PY, first, last, body, indent) == PY


def test_module_exports_only_the_spec_names():
    public = {n for n in dir(section) if not n.startswith("_")}
    assert {"SectionError", "find_section", "find_def", "brace_counts", "extract", "splice"} <= public


# ---- hoist_imports ------------------------------------------------------------ #

def test_hoist_moves_imports_into_the_function():
    body = "from datetime import date\nimport math\n\ndef f(x):\n    return math.floor(x)\n"
    assert hoist_imports(body) == "def f(x):\n    from datetime import date\n    import math\n    return math.floor(x)\n"


def test_hoist_keeps_decorators_and_the_docstring_first():
    body = 'import math\n@staticmethod\ndef f(x):\n    """Doc."""\n    return math.floor(x)\n'
    assert hoist_imports(body) == '@staticmethod\ndef f(x):\n    """Doc."""\n    import math\n    return math.floor(x)\n'


def test_hoist_keeps_a_multiline_import_together():
    body = "from os.path import (\n    join,\n    exists,\n)\ndef f():\n    return join\n"
    out = hoist_imports(body)
    assert out.startswith("def f():\n    from os.path import (\n")
    compile(out, "x", "exec")


def test_hoist_uses_the_body_indent():
    body = "import math\ndef f():\n  return math.pi\n"
    assert hoist_imports(body) == "def f():\n  import math\n  return math.pi\n"


@pytest.mark.parametrize("body", [
    "def f():\n    return 1\n",                                  # nothing to move
    "import math\ndef f(): return math.pi\n",                   # body on the def line
    "import math\ndef f():\n    return 1\ndef g():\n    return 2\n",   # two defs
    "import math\nX = 1\ndef f():\n    return X\n",           # other code between
    "import math\nclass C:\n    pass\n",                       # a class, not a def
    "import math\ndef f(:\n",                                  # does not parse
    "",
])
def test_hoist_leaves_other_shapes_alone(body):
    assert hoist_imports(body) == body
