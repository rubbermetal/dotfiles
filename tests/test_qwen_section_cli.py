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
    import os, sys
    part, spec = sys.argv[-1], sys.argv[-2]
    rec = os.environ["FAKE_RECORD"]
    open(rec + ".args", "w").write("\\n".join(sys.argv[1:]))
    open(rec + ".part", "w").write(open(part).read())
    open(rec + ".spec", "w").write(open(spec).read())
    mode = os.environ.get("FAKE_MODE", "write")
    if mode == "fail":
        sys.exit(3)
    if mode == "empty":
        open(part, "w").write("")
    elif mode == "same":
        pass
    else:
        open(part, "w").write(os.environ["FAKE_BODY"])
    sys.exit(0)
''')


@pytest.fixture
def box(tmp_path):
    fake = tmp_path / "fake-qwen-build"
    fake.write_text(FAKE)
    fake.chmod(0o755)
    (tmp_path / "page.html").write_text(PAGE)
    (tmp_path / "spec.txt").write_text("Make alpha return 5.\n")
    return tmp_path


def run(box, *args, mode="write", body="function alpha(a) {\n    return 5;\n}\n"):
    env = dict(os.environ, QWEN_BUILD=str(box / "fake-qwen-build"), FAKE_RECORD=str(box / "rec"),
               FAKE_MODE=mode, FAKE_BODY=body)
    return subprocess.run([sys.executable, str(SCRIPT), *args], cwd=box, env=env,
                          capture_output=True, text=True, timeout=60)


def page(box):
    return (box / "page.html").read_text()


def test_rewrites_only_the_section(box):
    r = run(box, "-s", r"function alpha\(", "spec.txt", "page.html")
    assert r.returncode == 0, r.stdout + r.stderr
    assert page(box) == PAGE.replace("        return 1;\n", "        return 5;\n")
    assert "lines 2-4" in r.stdout


def test_model_gets_the_dedented_section_in_a_part_file(box):
    run(box, "-s", r"function alpha\(", "spec.txt", "page.html")
    assert (box / "rec.part").read_text() == "function alpha(a) {\n    return 1;\n}\n"
    args = (box / "rec.args").read_text().split("\n")
    assert os.path.basename(args[-1]) == "qwen-section-part.html"
    assert os.path.dirname(os.path.abspath(box / args[-1])) == str(box)
    assert "--no-lint" in args
    assert args[args.index("--rules") + 1] == "none"
    assert args[args.index("-m") + 1] == "14b"


def test_spec_given_to_the_model_holds_the_user_spec_and_the_section_note(box):
    run(box, "-s", r"function alpha\(", "spec.txt", "page.html")
    spec = (box / "rec.spec").read_text()
    assert "Make alpha return 5." in spec
    assert "page.html" in spec and "lines 2-4" in spec


def test_part_file_is_removed_afterwards(box):
    run(box, "-s", r"function alpha\(", "spec.txt", "page.html")
    assert not (box / "qwen-section-part.html").exists()


def test_keep_leaves_the_part_file(box):
    run(box, "--keep", "-s", r"function alpha\(", "spec.txt", "page.html")
    assert (box / "qwen-section-part.html").read_text() == "function alpha(a) {\n    return 5;\n}\n"


def test_ext_and_model_options(box):
    run(box, "-m", "7b", "--ext", "js", "-s", r"function alpha\(", "spec.txt", "page.html")
    args = (box / "rec.args").read_text().split("\n")
    assert os.path.basename(args[-1]) == "qwen-section-part.js"
    assert args[args.index("-m") + 1] == "7b"
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
