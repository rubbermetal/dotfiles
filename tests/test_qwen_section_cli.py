"""qwen-section command: runs the real script with a fake qwen-build standing in for the model."""
import os
import pathlib
import subprocess
import sys
import textwrap

import pytest

ROOT = pathlib.Path(__file__).resolve().parent.parent
SCRIPT = ROOT / ".local" / "bin" / "qwen-section"

PAGE = (
    "<script>\n"                          # 1
    "    function alpha(a) {\n"           # 2
    "        return 1;\n"                 # 3
    "    }\n"                             # 4
    "    function beta() { return 2; }\n" # 5
    "</script>\n"                         # 6
)

# Fake qwen-build: last argument is the part file, the one before it the spec file.
# It records what it was given, then acts according to FAKE_MODE.
FAKE = textwrap.dedent('''\
    #!/usr/bin/env python3
    import os, subprocess, sys
    argv = sys.argv[1:]
    part, spec = argv[-1], argv[-2]
    model = argv[argv.index("-m") + 1]
    rec = os.environ["FAKE_RECORD"]
    open(rec + ".args", "w").write("\\n".join(argv))
    open(rec + ".models", "a").write(model + "\\n")
    open(rec + ".part", "w").write(open(part).read())
    open(rec + ".spec", "w").write(open(spec).read())
    mode = os.environ.get("FAKE_MODE_" + model.upper(), os.environ.get("FAKE_MODE", "write"))
    def check():
        cmd = argv[argv.index("--test-cmd") + 1]
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        open(rec + ".checks", "a").write("exit %d\\n%s----\\n" % (r.returncode, r.stdout))
        return r.returncode
    if mode == "hang":                        # writes a bad attempt into place, then never returns
        open(part, "w").write(os.environ["FAKE_BODY"])
        check()
        open(rec + ".hanging", "w").write("x")
        import time
        time.sleep(60)
    if mode == "fail":
        sys.exit(3)
    if mode == "empty":
        open(part, "w").write("")
    elif mode == "same":
        pass
    elif mode == "loop":                      # like aider: write, check, fix when the check fails
        open(part, "w").write(os.environ["FAKE_BODY"])
        if check() != 0:
            open(part, "w").write(os.environ["FAKE_BODY2"])
            check()
    else:
        open(part, "w").write(os.environ["FAKE_BODY"])
    sys.exit(0)
''')

PY = (
    "import os\n"                    # 1
    "\n"                             # 2
    "class Reader:\n"                # 3
    "    @staticmethod\n"            # 4
    "    def parse(x):\n"            # 5
    "        return 1\n"             # 6
    "\n"                             # 7
    "def tail():\n"                  # 8
    "    return 2\n"                 # 9
)

GOOD = "function alpha(a) {\n    return 5;\n}\n"


@pytest.fixture
def box(tmp_path):
    fake = tmp_path / "fake-qwen-build"
    fake.write_text(FAKE)
    fake.chmod(0o755)
    (tmp_path / "page.html").write_text(PAGE)
    (tmp_path / "spec.txt").write_text("Make alpha return 5.\n")
    return tmp_path


def run(box, *args, mode="write", body=GOOD, **extra):
    env = dict(os.environ, QWEN_BUILD=str(box / "fake-qwen-build"), FAKE_RECORD=str(box / "rec"),
               FAKE_MODE=mode, FAKE_BODY=body, **extra)
    return subprocess.run([sys.executable, str(SCRIPT), *args], cwd=box, env=env,
                          capture_output=True, text=True, timeout=60)


def page(box):
    return (box / "page.html").read_text()


def models(box):
    return (box / "rec.models").read_text().split()


def test_rewrites_only_the_section(box):
    r = run(box, "-s", r"function alpha\(", "spec.txt", "page.html")
    assert r.returncode == 0, r.stdout + r.stderr
    assert page(box) == PAGE.replace("        return 1;\n", "        return 5;\n")
    assert "lines 2-4" in r.stdout


def test_model_gets_the_dedented_section_in_a_part_file(box):
    run(box, "-s", r"function alpha\(", "spec.txt", "page.html")
    assert (box / "rec.part").read_text() == "function alpha(a) {\n    return 1;\n}\n"
    args = (box / "rec.args").read_text().split("\n")
    assert os.path.basename(args[-1]) == "qwen-section-part.js"      # inside <script>: js, not html
    assert os.path.dirname(os.path.abspath(box / args[-1])) == str(box)
    assert "--no-lint" in args
    assert args[args.index("--rules") + 1] == "none"
    assert args[args.index("-m") + 1] == "7b"            # -m auto starts with the 7b
    assert "--check" in args[args.index("--test-cmd") + 1]


def test_spec_given_to_the_model_holds_the_user_spec_and_the_section_note(box):
    run(box, "-s", r"function alpha\(", "spec.txt", "page.html")
    spec = (box / "rec.spec").read_text()
    assert "Make alpha return 5." in spec
    assert "lines 2-4" in spec
    assert "page.html" not in spec          # aider would add a file named in the prompt to the chat


def test_part_file_is_removed_afterwards(box):
    run(box, "-s", r"function alpha\(", "spec.txt", "page.html")
    assert not (box / "qwen-section-part.js").exists()
    assert [p.name for p in box.iterdir() if p.name.startswith("qwen-section-part")] == []


def test_keep_leaves_the_part_file(box):
    run(box, "--keep", "-s", r"function alpha\(", "spec.txt", "page.html")
    assert (box / "qwen-section-part.js").read_text() == "function alpha(a) {\n    return 5;\n}\n"


def test_ext_and_model_options(box):
    run(box, "-m", "14b", "--ext", "js", "-s", r"function alpha\(", "spec.txt", "page.html")
    args = (box / "rec.args").read_text().split("\n")
    assert os.path.basename(args[-1]) == "qwen-section-part.js"
    assert args[args.index("-m") + 1] == "14b"
    assert models(box) == ["14b"]
    assert not (box / "qwen-section-part.js").exists()


def test_end_pattern(box):
    r = run(box, "-s", "<script>", "-e", "</script>", "spec.txt", "page.html", body="<script>\n</script>\n")
    assert r.returncode == 0, r.stdout + r.stderr
    assert page(box) == "<script>\n</script>\n"
    assert "lines 1-6" in r.stdout


def test_line_range(box):
    r = run(box, "-l", "5-5", "spec.txt", "page.html", body="function beta() { return 9; }\n")
    assert r.returncode == 0, r.stdout + r.stderr
    assert page(box) == PAGE.replace("return 2;", "return 9;")
    assert (box / "rec.part").read_text() == "function beta() { return 2; }\n"


def test_dry_run_shows_the_section_and_calls_nothing(box):
    r = run(box, "-n", "-s", r"function alpha\(", "spec.txt", "page.html")
    assert r.returncode == 0
    assert "lines 2-4" in r.stdout
    assert "function alpha(a) {\n    return 1;\n}" in r.stdout
    assert not (box / "rec.args").exists()
    assert page(box) == PAGE
    assert not (box / "qwen-section-part.html").exists()


def test_section_not_found(box):
    r = run(box, "-s", "function gamma", "spec.txt", "page.html")
    assert r.returncode == 2
    assert "no line matches" in r.stdout + r.stderr
    assert not (box / "rec.args").exists()
    assert page(box) == PAGE


def test_missing_target(box):
    r = run(box, "-s", "x", "spec.txt", "nope.html")
    assert r.returncode == 2
    assert not (box / "rec.args").exists()


def test_needs_start_or_lines(box):
    r = run(box, "spec.txt", "page.html")
    assert r.returncode == 2
    assert page(box) == PAGE


@pytest.mark.parametrize("lines", ["5", "a-b", "4-2", "0-3", "2-99"])
def test_bad_line_range(box, lines):
    r = run(box, "-l", lines, "spec.txt", "page.html")
    assert r.returncode == 2
    assert page(box) == PAGE
    assert not (box / "rec.args").exists()


def test_build_failure_leaves_the_target_alone(box):
    r = run(box, "-s", r"function alpha\(", "spec.txt", "page.html", mode="fail")
    assert r.returncode == 3
    assert page(box) == PAGE
    assert not (box / "qwen-section-part.html").exists()


def test_empty_result_leaves_the_target_alone(box):
    r = run(box, "-s", r"function alpha\(", "spec.txt", "page.html", mode="empty")
    assert r.returncode == 3
    assert page(box) == PAGE


def test_unbalanced_braces_are_rejected(box):
    r = run(box, "-s", r"function alpha\(", "spec.txt", "page.html", body="function alpha(a) {\n    return 5;\n")
    assert r.returncode == 3
    assert "brace" in (r.stdout + r.stderr).lower()
    assert page(box) == PAGE


def test_brace_check_is_skipped_when_the_old_section_was_unbalanced(box):
    r = run(box, "-l", "2-3", "spec.txt", "page.html", body="function alpha(a) {\n    return 7;\n")
    assert r.returncode == 0, r.stdout + r.stderr
    assert "        return 7;\n" in page(box)


def test_no_change_is_reported(box):
    r = run(box, "-s", r"function alpha\(", "spec.txt", "page.html", mode="same")
    assert r.returncode == 0
    assert "no change" in r.stdout.lower()
    assert page(box) == PAGE


def test_tests_run_after_the_splice(box):
    (box / "test_ok.py").write_text("def test_it():\n    assert 'return 5' in open('page.html').read()\n")
    r = run(box, "-t", "test_ok.py", "-s", r"function alpha\(", "spec.txt", "page.html")
    assert r.returncode == 0, r.stdout + r.stderr
    assert "1 passed" in r.stdout


def test_failing_tests_give_exit_4_and_keep_the_new_text(box):
    (box / "test_bad.py").write_text("def test_it():\n    assert False\n")
    r = run(box, "-t", "test_bad.py", "-s", r"function alpha\(", "spec.txt", "page.html")
    assert r.returncode == 4
    assert "1 failed" in r.stdout
    assert "return 5" in page(box)


def test_target_without_final_newline_stays_that_way(box):
    (box / "page.html").write_text(PAGE.rstrip("\n"))
    r = run(box, "-s", r"function alpha\(", "spec.txt", "page.html")
    assert r.returncode == 0
    assert not page(box).endswith("\n")
    assert "return 5" in page(box)


# ---- model choice ---------------------------------------------------------- #

def test_auto_stops_at_the_7b_when_it_succeeds(box):
    r = run(box, "-s", r"function alpha\(", "spec.txt", "page.html")
    assert r.returncode == 0
    assert models(box) == ["7b"]


def test_auto_escalates_to_the_14b_from_the_original(box):
    r = run(box, "-s", r"function alpha\(", "spec.txt", "page.html", FAKE_MODE_7B="empty")
    assert r.returncode == 0, r.stdout + r.stderr
    assert models(box) == ["7b", "14b"]
    assert (box / "rec.part").read_text() == "function alpha(a) {\n    return 1;\n}\n"   # what the 14b was given
    assert "return 5" in page(box)
    assert "trying the 14b" in r.stdout


def test_auto_escalates_when_the_build_fails(box):
    r = run(box, "-s", r"function alpha\(", "spec.txt", "page.html", FAKE_MODE_7B="fail")
    assert r.returncode == 0
    assert models(box) == ["7b", "14b"]


def test_auto_gives_up_after_the_14b(box):
    r = run(box, "-s", r"function alpha\(", "spec.txt", "page.html", mode="empty")
    assert r.returncode == 3
    assert models(box) == ["7b", "14b"]
    assert page(box) == PAGE


def test_auto_escalates_on_failing_tests_and_restores_between_models(box):
    (box / "test_five.py").write_text("def test_it():\n    assert 'return 5' in open('page.html').read()\n")
    r = run(box, "--passes", "1", "-t", "test_five.py", "-s", r"function alpha\(", "spec.txt", "page.html",
            FAKE_MODE_7B="write", FAKE_MODE_14B="same", body="function alpha(a) {\n    return 6;\n}\n")
    assert models(box) == ["7b", "14b"]
    assert r.returncode == 0                 # the 14b made no change: the 7b's text must be gone
    assert page(box) == PAGE


def test_explicit_model_does_not_escalate(box):
    r = run(box, "-m", "7b", "-s", r"function alpha\(", "spec.txt", "page.html", mode="empty")
    assert r.returncode == 3
    assert models(box) == ["7b"]


# ---- the check the model's fix loop runs ----------------------------------- #

def checks(box):
    return (box / "rec.checks").read_text()


def test_check_feeds_problems_back_and_accepts_the_fix(box):
    r = run(box, "-s", r"function alpha\(", "spec.txt", "page.html", mode="loop",
            body="function alpha(a) {\n    return 5;\n", FAKE_BODY2=GOOD)
    assert r.returncode == 0, r.stdout + r.stderr
    first, second = checks(box).split("----\n")[:2]
    assert first.startswith("exit 1") and "Unbalanced braces" in first
    assert second.startswith("exit 0")
    assert "return 5" in page(box)
    assert models(box) == ["7b"]


def test_check_runs_the_tests_with_the_section_in_place(box):
    (box / "test_five.py").write_text("def test_it():\n    assert 'return 5' in open('page.html').read()\n")
    r = run(box, "-t", "test_five.py", "-s", r"function alpha\(", "spec.txt", "page.html", mode="loop",
            body="function alpha(a) {\n    return 6;\n}\n", FAKE_BODY2=GOOD)
    assert r.returncode == 0, r.stdout + r.stderr
    first, second = checks(box).split("----\n")[:2]
    assert first.startswith("exit 1") and "test_five.py" in first and "assert" in first
    assert second.startswith("exit 0")
    assert "1 passed" in r.stdout


def test_rejected_attempt_is_saved_for_review(box):
    r = run(box, "-m", "7b", "-s", r"function alpha\(", "spec.txt", "page.html", body="function alpha(a) {\n")
    assert r.returncode == 3
    saved = [w for w in r.stdout.split() if "attempt-7b" in w]
    assert saved and open(saved[0]).read() == "function alpha(a) {\n"


@pytest.mark.skipif(not __import__("shutil").which("node"), reason="node not installed")
def test_javascript_syntax_error_is_rejected(box):
    r = run(box, "-m", "7b", "--ext", "js", "-s", r"function alpha\(", "spec.txt", "page.html",
            body="function alpha(a) {\n    return 5 +;\n}\n")
    assert r.returncode == 3
    assert "JavaScript syntax error" in r.stdout
    assert page(box) == PAGE


@pytest.mark.skipif(not __import__("shutil").which("node"), reason="node not installed")
def test_javascript_check_is_skipped_for_a_fragment_that_never_parsed(box):
    # line 2 alone ("function alpha(a) {") is not a script, so its rewrite cannot be judged by node
    r = run(box, "-m", "7b", "--ext", "js", "-l", "2-2", "spec.txt", "page.html", body="function alpha(b) {\n")
    assert r.returncode == 0, r.stdout + r.stderr
    assert "    function alpha(b) {\n" in page(box)


# ---- Python targets -------------------------------------------------------- #

@pytest.fixture
def pybox(box):
    (box / "mod.py").write_text(PY)
    return box


def test_def_selects_a_method_with_its_decorator(pybox):
    r = run(pybox, "-d", "Reader.parse", "spec.txt", "mod.py", body="@staticmethod\ndef parse(x):\n    return 10\n")
    assert r.returncode == 0, r.stdout + r.stderr
    assert "lines 4-6" in r.stdout
    assert (pybox / "rec.part").read_text() == "@staticmethod\ndef parse(x):\n    return 1\n"
    assert (pybox / "mod.py").read_text() == PY.replace("        return 1\n", "        return 10\n")
    assert os.path.basename((pybox / "rec.args").read_text().split("\n")[-1]) == "qwen-section-part.py"


def test_def_not_found(pybox):
    r = run(pybox, "-d", "nope", "spec.txt", "mod.py")
    assert r.returncode == 2
    assert "no def or class named" in r.stdout


def test_python_syntax_error_is_rejected_with_the_section_line(pybox):
    r = run(pybox, "-m", "7b", "-d", "tail", "spec.txt", "mod.py", body="def tail():\n    return (2\n")
    assert r.returncode == 3
    assert "Python syntax error" in r.stdout
    assert "of the section" in r.stdout
    assert (pybox / "mod.py").read_text() == PY


def test_python_wrong_indentation_is_rejected(pybox):
    r = run(pybox, "-m", "7b", "-d", "tail", "spec.txt", "mod.py", body="def tail():\nreturn 2\n")
    assert r.returncode == 3
    assert (pybox / "mod.py").read_text() == PY


def test_refs_are_passed_to_the_builder(pybox):
    run(pybox, "-r", "a.py", "-r", "b.py", "-R", "c.txt", "-d", "tail", "spec.txt", "mod.py", body="def tail():\n    return 3\n")
    args = (pybox / "rec.args").read_text().split("\n")
    assert [args[i + 1] for i, x in enumerate(args) if x == "-r"] == ["a.py", "b.py"]
    assert args[args.index("-R") + 1] == "c.txt"
    assert args[-1].endswith("qwen-section-part.py")


def test_only_one_selector(pybox):
    assert run(pybox, "-d", "tail", "-l", "8-9", "spec.txt", "mod.py").returncode == 2
    assert run(pybox, "-e", "x", "-l", "8-9", "spec.txt", "mod.py").returncode == 2
    assert not (pybox / "rec.args").exists()


# ---- structure: the section stays one block at the same place --------------- #

def test_renamed_function_is_rejected(box):
    r = run(box, "-m", "7b", "-s", r"function alpha\(", "spec.txt", "page.html",
            body="function alphaTwo(a) {\n    return 5;\n}\n")
    assert r.returncode == 3
    assert "no longer be found" in r.stdout
    assert page(box) == PAGE


def test_extra_code_after_a_brace_block_is_rejected(box):
    r = run(box, "-m", "7b", "-s", r"function alpha\(", "spec.txt", "page.html",
            body=GOOD + "function helper() {\n    return 0;\n}\n")
    assert r.returncode == 3
    assert "ONE block" in r.stdout and "line 4" in r.stdout
    assert page(box) == PAGE


def test_repeating_the_first_line_is_rejected(box):
    r = run(box, "-m", "7b", "-s", r"function alpha\(", "spec.txt", "page.html",
            body="function alpha(a) {\n    function alpha(b) { return 1; }\n    return 5;\n}\n")
    assert r.returncode == 3
    assert "no longer be found" in r.stdout


def test_loose_allows_extra_code(box):
    r = run(box, "-m", "7b", "--loose", "-s", r"function alpha\(", "spec.txt", "page.html",
            body=GOOD + "function helper() {\n    return 0;\n}\n")
    assert r.returncode == 0, r.stdout + r.stderr
    assert "    function helper() {\n" in page(box)


def test_renamed_def_is_rejected(pybox):
    r = run(pybox, "-m", "7b", "-d", "tail", "spec.txt", "mod.py", body="def tail2():\n    return 2\n")
    assert r.returncode == 3
    assert "no longer be found" in r.stdout and "'tail'" in r.stdout
    assert (pybox / "mod.py").read_text() == PY


def test_extra_def_after_the_def_is_rejected(pybox):
    r = run(pybox, "-m", "7b", "-d", "Reader.parse", "spec.txt", "mod.py",
            body="@staticmethod\ndef parse(x):\n    return 10\n\ndef extra():\n    return 0\n")
    assert r.returncode == 3
    assert "ONE block" in r.stdout
    assert (pybox / "mod.py").read_text() == PY


def test_helper_inside_the_def_is_fine(pybox):
    r = run(pybox, "-m", "7b", "-d", "tail", "spec.txt", "mod.py",
            body="def tail():\n    def helper():\n        return 2\n\n    return helper()\n")
    assert r.returncode == 0, r.stdout + r.stderr


def test_end_marker_must_stay_last(box):
    (box / "page.html").write_text("<p>a</p>\n<!-- BEGIN -->\n<p>b</p>\n<!-- END -->\n<p>c</p>\n")
    r = run(box, "-m", "7b", "-s", "BEGIN", "-e", "END", "spec.txt", "page.html",
            body="<!-- BEGIN -->\n<p>B</p>\n<!-- END -->\n<p>extra</p>\n")
    assert r.returncode == 3
    assert "LAST line" in r.stdout
    r = run(box, "-m", "7b", "-s", "BEGIN", "-e", "END", "spec.txt", "page.html",
            body="<!-- BEGIN -->\n<p>B</p>\n<!-- END -->\n")
    assert r.returncode == 0, r.stdout + r.stderr
    assert page(box) == "<p>a</p>\n<!-- BEGIN -->\n<p>B</p>\n<!-- END -->\n<p>c</p>\n"


# ---- HTML / Jinja targets --------------------------------------------------- #

TPL = (
    "<div class=\"card\">\n"                 # 1
    "  <!-- BEGIN list -->\n"                # 2
    "  <ul>\n"                               # 3
    "    {% for r in rows %}\n"              # 4
    "    <li>{{ r }}</li>\n"                 # 5
    "    {% endfor %}\n"                     # 6
    "  </ul>\n"                              # 7
    "  <!-- END list -->\n"                  # 8
    "</div>\n"                               # 9
    "<script>\n"                             # 10
    "  function go() {\n"                    # 11
    "    const a = 1;\n"                     # 12
    "    return a;\n"                        # 13
    "  }\n"                                  # 14
    "</script>\n"                            # 15
)
LIST_OK = "<!-- BEGIN list -->\n<ol>\n  {% for r in rows %}\n  <li>{{ r }}</li>\n  {% endfor %}\n</ol>\n<!-- END list -->\n"


@pytest.fixture
def tbox(box):
    (box / "t.html").write_text(TPL)
    return box


def tpl(args, tbox, body, **kw):
    return run(tbox, "-m", "7b", *args, "spec.txt", "t.html", body=body, **kw)


def test_template_edit_that_keeps_structure_passes(tbox):
    r = tpl(["-s", "BEGIN list", "-e", "END list"], tbox, LIST_OK)
    assert r.returncode == 0, r.stdout + r.stderr
    assert "  <ol>\n" in (tbox / "t.html").read_text()


def test_dropped_closing_tag_is_rejected(tbox):
    r = tpl(["-s", "BEGIN list", "-e", "END list"], tbox, LIST_OK.replace("</ol>\n", ""))
    assert r.returncode == 3
    assert "<ol>: 1 more opening tag than before" in r.stdout
    assert (tbox / "t.html").read_text() == TPL


def test_extra_closing_tag_is_rejected(tbox):
    r = tpl(["-s", "BEGIN list", "-e", "END list"], tbox, LIST_OK.replace("</ol>\n", "</ol>\n</div>\n"))
    assert r.returncode == 3
    assert "<div>: 1 more closing tag than before" in r.stdout


def test_loose_skips_the_tag_check(tbox):
    r = tpl(["--loose", "-s", "BEGIN list", "-e", "END list"], tbox, LIST_OK.replace("</ol>\n", ""))
    assert r.returncode == 0, r.stdout + r.stderr


def test_jinja_error_is_rejected_with_the_section_line(tbox):
    pytest.importorskip("jinja2")
    r = tpl(["-s", "BEGIN list", "-e", "END list"], tbox, LIST_OK.replace("  {% endfor %}\n", ""))
    assert r.returncode == 3
    assert "Jinja template syntax error" in r.stdout
    assert "of the section" in r.stdout
    assert (tbox / "t.html").read_text() == TPL


def test_jinja_check_is_skipped_when_the_template_never_parsed(tbox):
    pytest.importorskip("jinja2")
    (tbox / "t.html").write_text(TPL + "{% custom_tag %}\n")
    r = tpl(["-s", "BEGIN list", "-e", "END list"], tbox, LIST_OK)
    assert r.returncode == 0, r.stdout + r.stderr


@pytest.mark.skipif(not __import__("shutil").which("node"), reason="node not installed")
def test_fragment_edit_that_breaks_the_script_is_rejected(tbox):
    # two lines from the middle of a function: only the whole <script> can be judged
    r = tpl(["-l", "11-12"], tbox, "function go() {\n  const a = 1 +;\n")
    assert r.returncode == 3
    assert "JavaScript syntax error in the <script> block" in r.stdout
    assert (tbox / "t.html").read_text() == TPL
    r = tpl(["-l", "11-12"], tbox, "function go() {\n  const a = 2;\n")
    assert r.returncode == 0, r.stdout + r.stderr


@pytest.mark.skipif(not __import__("shutil").which("node"), reason="node not installed")
def test_script_check_is_skipped_when_the_script_never_parsed(tbox):
    (tbox / "t.html").write_text(TPL.replace("const a = 1;", "const a = {{ value }};"))
    r = tpl(["-l", "11-12"], tbox, "function go() {\n  const a = {{ value }} +;\n")
    assert r.returncode == 0, r.stdout + r.stderr


# ---- batch ------------------------------------------------------------------ #

def batch(box, jobs, **kw):
    (box / "jobs.txt").write_text(jobs)
    env = dict(os.environ, QWEN_BUILD=str(box / "fake-qwen-build"), FAKE_RECORD=str(box / "rec"),
               FAKE_MODE="write", **kw)
    return subprocess.run([sys.executable, str(SCRIPT), "--batch", "jobs.txt", "page.html"], cwd=box, env=env,
                          capture_output=True, text=True, timeout=120)


BETA9 = "function beta() { return 9; }\n"


def test_batch_runs_each_job_on_the_file_the_one_before_left(box):
    # FAKE_BODY is the same for every job, so use bodies that fit only via per-job checks:
    # job 1 grows alpha by one line; job 2 must then find beta one line lower.
    grown = "function alpha(a) {\n    const x = 5;\n    return x;\n}\n"
    r = batch(box, "# two jobs\n\n== -m 7b -s 'function alpha\\('\nGrow alpha.\n== -m 7b -n -s 'function beta\\('\nShow beta.\n",
              FAKE_BODY=grown)
    assert r.returncode == 0, r.stdout + r.stderr
    assert "== job 1/2" in r.stdout and "== job 2/2" in r.stdout
    assert "lines 2-4" in r.stdout and "lines 6-6" in r.stdout
    assert "2 jobs done" in r.stdout
    assert "        const x = 5;\n" in page(box)


def test_batch_gives_each_job_its_own_spec(box):
    r = batch(box, "== -m 7b -s 'function beta\\('\nMake beta return 9.\nSecond spec line.\n", FAKE_BODY=BETA9)
    assert r.returncode == 0, r.stdout + r.stderr
    spec = (box / "rec.spec").read_text()
    assert "Make beta return 9.\nSecond spec line." in spec
    assert "return 9" in page(box)


def test_batch_stops_at_the_first_failure(box):
    r = batch(box, "== -m 7b -s 'function gamma'\nNo such thing.\n== -m 7b -s 'function beta\\('\nNine.\n", FAKE_BODY=BETA9)
    assert r.returncode == 2
    assert "job 1 failed (exit 2); 1 job not run" in r.stdout
    assert page(box) == PAGE
    assert not (box / "rec.args").exists()


def test_batch_keeps_earlier_jobs_when_a_later_one_fails(box):
    r = batch(box, "== -m 7b -s 'function beta\\('\nNine.\n== -m 7b -s 'function alpha\\('\nBreak it.\n", FAKE_BODY=BETA9)
    assert r.returncode == 3                 # beta's body is not a valid alpha: rejected
    assert "return 9" in page(box)
    assert "        return 1;\n" in page(box)


@pytest.mark.parametrize("jobs,words", [
    ("", "no == line"),
    ("text first\n== -l 1-1\nx\n", "before the first =="),
    ("==\nx\n", "no options"),
    ("== -l 1-1\n\n", "no spec text"),
    ("== -s 'unclosed\nx\n", "line 1"),
])
def test_batch_malformed_jobs_file(box, jobs, words):
    r = batch(box, jobs, FAKE_BODY=BETA9)
    assert r.returncode == 2
    assert words in r.stdout
    assert page(box) == PAGE


def test_batch_usage_and_missing_file(box):
    env = dict(os.environ, QWEN_BUILD=str(box / "fake-qwen-build"), FAKE_RECORD=str(box / "rec"))
    r = subprocess.run([sys.executable, str(SCRIPT), "--batch", "nope.txt", "page.html"], cwd=box, env=env, capture_output=True, text=True)
    assert r.returncode == 2 and "no such jobs file" in r.stdout
    r = subprocess.run([sys.executable, str(SCRIPT), "--batch", "jobs.txt"], cwd=box, env=env, capture_output=True, text=True)
    assert r.returncode == 2 and "usage" in r.stdout


# ---- part file extension ---------------------------------------------------- #

def part_name(box):
    return os.path.basename((box / "rec.args").read_text().split("\n")[-1])


def test_ext_is_html_outside_script_and_style(tbox):
    tpl(["-s", "BEGIN list", "-e", "END list"], tbox, LIST_OK)
    assert part_name(tbox) == "qwen-section-part.html"


def test_ext_is_css_inside_style(tbox):
    (tbox / "t.html").write_text("<style>\n  .a {\n    color: red;\n  }\n</style>\n" + TPL)
    r = tpl(["-s", r"\.a \{"], tbox, ".a {\n  color: blue;\n}\n")
    assert r.returncode == 0, r.stdout + r.stderr
    assert part_name(tbox) == "qwen-section-part.css"


def test_ext_stays_html_when_the_section_holds_the_script_tags(box):
    run(box, "-m", "7b", "-s", "<script>", "-e", "</script>", "spec.txt", "page.html", body="<script>\n</script>\n")
    assert part_name(box) == "qwen-section-part.html"


def test_ext_is_not_guessed_for_non_templates(pybox):
    (pybox / "mod.py").write_text('X = "<script>"\n' + PY)
    run(pybox, "-m", "7b", "-d", "tail", "spec.txt", "mod.py", body="def tail():\n    return 3\n")
    assert part_name(pybox) == "qwen-section-part.py"


# ---- CSS -------------------------------------------------------------------- #

SHEET = (
    ".a {\n"                 # 1
    "  color: red;\n"        # 2
    "  margin: 0;\n"         # 3
    "}\n"                    # 4
    ".b {\n"                 # 5
    "  color: blue;\n"       # 6
    "}\n"                    # 7
)


@pytest.fixture
def cbox(box):
    (box / "s.css").write_text(SHEET)
    (box / "t.html").write_text("<style>\n" + SHEET + "</style>\n" + TPL)
    return box


def css(cbox, args, body, target="s.css"):
    return run(cbox, "-m", "7b", *args, "spec.txt", target, body=body)


def test_css_rule_edit_passes(cbox):
    r = css(cbox, ["-s", r"^\.a \{"], ".a {\n  color: green;\n  margin: 0;\n}\n")
    assert r.returncode == 0, r.stdout + r.stderr
    assert (cbox / "s.css").read_text() == SHEET.replace("red", "green")


def test_css_missing_semicolon_is_rejected(cbox):
    r = css(cbox, ["-s", r"^\.a \{"], ".a {\n  color: green\n  margin: 0;\n}\n")
    assert r.returncode == 3
    assert "CSS error: missing ; after: color: green at line 2 of the section" in r.stdout
    assert (cbox / "s.css").read_text() == SHEET


def test_css_missing_colon_is_rejected(cbox):
    r = css(cbox, ["-s", r"^\.b \{"], ".b {\n  color blue;\n}\n")
    assert r.returncode == 3
    assert "not a declaration" in r.stdout


def test_css_fragment_is_judged_in_the_whole_file(cbox):
    # two declaration lines are not a sheet by themselves; the file as a whole is checked
    r = css(cbox, ["-l", "2-3"], "color: green\nmargin: 0;\n")
    assert r.returncode == 3
    assert "CSS error: missing ;" in r.stdout and "of the section" in r.stdout
    r = css(cbox, ["-l", "2-3"], "color: green;\nmargin: 1px;\n")
    assert r.returncode == 0, r.stdout + r.stderr


def test_css_unclosed_comment_is_rejected(cbox):
    r = css(cbox, ["-l", "6-6"], "color: blue; /* note\n")
    assert r.returncode == 3
    assert "never closed" in r.stdout


def test_css_check_is_skipped_for_a_file_that_was_not_sound(cbox):
    (cbox / "s.css").write_text(SHEET + "$placeholder$\n")
    r = css(cbox, ["-l", "2-3"], "color: green\nmargin: 0;\n")
    assert r.returncode == 0, r.stdout + r.stderr


def test_style_block_in_a_template_is_checked(cbox):
    r = css(cbox, ["-s", r"^\.a \{"], ".a {\n  color: green\n  margin: 0;\n}\n", target="t.html")
    assert r.returncode == 3
    assert "CSS error" in r.stdout
    assert part_name(cbox) == "qwen-section-part.css"
    r = css(cbox, ["-l", "3-4"], "color: green\nmargin: 0;\n", target="t.html")       # a fragment
    assert r.returncode == 3
    assert "CSS error in the <style> block" in r.stdout
    r = css(cbox, ["-l", "3-4"], "color: green;\nmargin: 0;\n", target="t.html")
    assert r.returncode == 0, r.stdout + r.stderr


# ---- lines put in front of the section --------------------------------------- #

def test_imports_above_a_def_are_moved_inside_it(pybox):
    r = run(pybox, "-m", "7b", "-d", "tail", "spec.txt", "mod.py",
            body="from datetime import date, timedelta\nimport math\n\ndef tail():\n    return math.floor(2.5)\n")
    assert r.returncode == 0, r.stdout + r.stderr
    assert (pybox / "mod.py").read_text() == PY.replace(
        "def tail():\n    return 2\n",
        "def tail():\n    from datetime import date, timedelta\n    import math\n    return math.floor(2.5)\n")


def test_imports_above_a_one_line_def_get_a_specific_instruction(pybox):
    # a body on the def line cannot take the imports, so the model is told what to do
    r = run(pybox, "-m", "7b", "--passes", "1", "-d", "tail", "spec.txt", "mod.py",
            body="from datetime import date, timedelta\nimport math\n\ndef tail(): return math.floor(2.5)\n")
    assert r.returncode == 3
    assert "must start with: def tail():" in r.stdout
    assert "INSIDE the function" in r.stdout
    assert "        from datetime import date, timedelta" in r.stdout and "        import math" in r.stdout
    assert (pybox / "mod.py").read_text() == PY


def test_imports_inside_the_def_are_accepted(pybox):
    r = run(pybox, "-m", "7b", "-d", "tail", "spec.txt", "mod.py",
            body="def tail():\n    import math\n    return math.floor(2.5)\n")
    assert r.returncode == 0, r.stdout + r.stderr


def test_other_lines_above_a_def_are_named(pybox):
    r = run(pybox, "-m", "7b", "-d", "tail", "spec.txt", "mod.py", body="LIMIT = 3\n\ndef tail():\n    return LIMIT\n")
    assert r.returncode == 3
    assert "1 line before the section's first line" in r.stdout
    assert "must start with: def tail():" in r.stdout


def test_python_note_tells_the_model_where_imports_go(pybox):
    run(pybox, "-m", "7b", "-d", "tail", "spec.txt", "mod.py", body="def tail():\n    return 3\n")
    assert "INSIDE the function body" in (pybox / "rec.spec").read_text()
    run(pybox, "-m", "7b", "-s", r"function alpha\(", "spec.txt", "page.html")
    assert "INSIDE the function body" not in (pybox / "rec.spec").read_text()


# ---- a killed run cleans up --------------------------------------------------- #

@pytest.mark.parametrize("sig", ["SIGTERM", "SIGINT"])
def test_killed_run_restores_the_target_and_removes_the_part(box, sig):
    import signal
    import time
    (box / "test_never.py").write_text("def test_it():\n    assert False\n")
    env = dict(os.environ, QWEN_BUILD=str(box / "fake-qwen-build"), FAKE_RECORD=str(box / "rec"),
               FAKE_MODE="hang", FAKE_BODY=GOOD)
    p = subprocess.Popen([sys.executable, str(SCRIPT), "-m", "7b", "-t", "test_never.py", "-s", r"function alpha\(",
                          "spec.txt", "page.html"], cwd=box, env=env, stdout=subprocess.PIPE, text=True)
    for _ in range(200):
        if (box / "rec.hanging").exists():
            break
        time.sleep(0.05)
    assert "return 5" in page(box)             # the failing attempt is in place while the model "works"
    p.send_signal(getattr(signal, sig))
    out, _ = p.communicate(timeout=20)
    assert p.returncode == 130
    assert "interrupted" in out
    assert page(box) == PAGE
    assert not (box / "qwen-section-part.js").exists()


# ---- hoisting runs before the checks; second pass per model ------------------ #

def test_hoisting_keeps_a_docstring_first(pybox):
    r = run(pybox, "-m", "7b", "-d", "tail", "spec.txt", "mod.py",
            body='import math\ndef tail():\n    """Two."""\n    return math.floor(2.5)\n')
    assert r.returncode == 0, r.stdout + r.stderr
    assert '    def tail():\n        """Two."""\n        import math\n' not in (pybox / "mod.py").read_text()   # top level, no indent
    assert 'def tail():\n    """Two."""\n    import math\n    return math.floor(2.5)\n' in (pybox / "mod.py").read_text()


def test_second_pass_continues_from_the_attempt_with_the_problems(box):
    (box / "test_five.py").write_text("def test_it():\n    assert 'return 5' in open('page.html').read()\n")
    r = run(box, "-m", "7b", "--passes", "2", "-t", "test_five.py", "-s", r"function alpha\(", "spec.txt", "page.html",
            body="function alpha(a) {\n    return 6;\n}\n")
    assert r.returncode == 4
    assert models(box) == ["7b", "7b"]
    assert "7b pass 2: continuing from its attempt" in r.stdout
    assert (box / "rec.part").read_text() == "function alpha(a) {\n    return 6;\n}\n"   # pass 2 got the attempt
    spec = (box / "rec.spec").read_text()
    assert "your previous attempt" in spec and "test_five.py" in spec
    assert "Make alpha return 5." in spec


def test_auto_runs_one_pass_per_model_by_default(box):
    r = run(box, "-s", r"function alpha\(", "spec.txt", "page.html", body="function alpha(a) {\n")
    assert r.returncode == 3
    assert models(box) == ["7b", "14b"]


def test_auto_with_two_passes(box):
    r = run(box, "--passes", "2", "-s", r"function alpha\(", "spec.txt", "page.html", body="function alpha(a) {\n")
    assert r.returncode == 3
    assert models(box) == ["7b", "7b", "14b", "14b"]
    assert "trying the 14b" in r.stdout


def test_no_second_pass_after_an_empty_or_failed_run(box):
    r = run(box, "--passes", "2", "-s", r"function alpha\(", "spec.txt", "page.html", mode="empty")
    assert models(box) == ["7b", "14b"]
    (box / "rec.models").unlink()
    r = run(box, "--passes", "2", "-s", r"function alpha\(", "spec.txt", "page.html", mode="fail")
    assert r.returncode == 3
    assert models(box) == ["7b", "14b"]


def test_passes_one_is_a_single_run(box):
    r = run(box, "-m", "14b", "--passes", "1", "-s", r"function alpha\(", "spec.txt", "page.html", body="function alpha(a) {\n")
    assert r.returncode == 3
    assert models(box) == ["14b"]
