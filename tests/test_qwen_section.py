"""section.py: find a block in a big file, pull it out, put a rewritten one back."""
import pathlib
import sys

import pytest

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / ".local" / "share" / "qwen-build"))

import section  # noqa: E402
from section import SectionError, extract, find_section, splice  # noqa: E402

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


def test_module_exports_only_the_spec_names():
    public = {n for n in dir(section) if not n.startswith("_")}
    assert {"SectionError", "find_section", "extract", "splice"} <= public
