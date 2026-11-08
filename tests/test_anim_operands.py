"""anim operands: which files, mode, url and output name a command line refers to."""
import importlib.util
import pathlib
import re
import sys

import pytest

ROOT = pathlib.Path(__file__).resolve().parent.parent
SHARE = ROOT / ".local" / "share" / "anim"
sys.path.insert(0, str(SHARE))


def _load(name):
    spec = importlib.util.spec_from_file_location("anim_" + name, SHARE / (name + ".py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

operands = _load("operands")


# ---- parse_operands ------------------------------------------------------- #

def P(cmd, *args):
    return operands.parse_operands(cmd, list(args))


def test_parse_result_always_has_all_keys():
    r = P("mv", "a", "b")
    assert set(r) == {"sources", "dest", "mode", "url", "output"}


def test_unknown_command_has_empty_result():
    r = P("ls", "-l", "x")
    assert r["sources"] == [] and r["dest"] is None and r["mode"] is None
    assert r["url"] is None and r["output"] is None


@pytest.mark.parametrize("cmd", ["mv", "cp"])
def test_move_copy_basic(cmd):
    r = P(cmd, "-vi", "a", "b")
    assert r["sources"] == ["a"] and r["dest"] == "b"


@pytest.mark.parametrize("cmd", ["mv", "cp"])
def test_move_copy_many_sources(cmd):
    r = P(cmd, "a", "b", "dir/")
    assert r["sources"] == ["a", "b"] and r["dest"] == "dir/"


def test_double_dash_ends_options():
    r = P("mv", "--", "-weird", "dest")
    assert r["sources"] == ["-weird"] and r["dest"] == "dest"


def test_target_directory_short_option():
    r = P("cp", "-t", "dir", "a", "b")
    assert r["sources"] == ["a", "b"] and r["dest"] == "dir"


def test_target_directory_long_option():
    r = P("mv", "--target-directory=dir", "a")
    assert r["sources"] == ["a"] and r["dest"] == "dir"


def test_rm_collects_files_and_ignores_options():
    r = P("rm", "-I", "--preserve-root", "-rf", "a", "b")
    assert r["sources"] == ["a", "b"] and r["dest"] is None


def test_rm_double_dash():
    assert P("rm", "--", "-f")["sources"] == ["-f"]


def test_chmod_numeric_mode():
    r = P("chmod", "-v", "--preserve-root", "755", "f1", "f2")
    assert r["mode"] == "755" and r["sources"] == ["f1", "f2"]


def test_chmod_symbolic_mode_after_recursive_flag():
    r = P("chmod", "-R", "u+x", "dir")
    assert r["mode"] == "u+x" and r["sources"] == ["dir"]


def test_chmod_mode_that_looks_like_an_option():
    r = P("chmod", "-w", "file")
    assert r["mode"] == "-w" and r["sources"] == ["file"]


def test_chmod_reference_has_no_mode():
    r = P("chmod", "--reference=ref", "f")
    assert r["mode"] is None and r["sources"] == ["f"]


def test_rsync_basic():
    r = P("rsync", "-avz", "src/", "host:dst/")
    assert r["sources"] == ["src/"] and r["dest"] == "host:dst/"


def test_rsync_skips_option_arguments():
    r = P("rsync", "-e", "ssh", "--exclude", "*.tmp", "a", "b")
    assert r["sources"] == ["a"] and r["dest"] == "b"


def test_rsync_equals_form_options():
    r = P("rsync", "--exclude=*.tmp", "-a", "a", "b")
    assert r["sources"] == ["a"] and r["dest"] == "b"


def test_curl_output_option():
    r = P("curl", "-sS", "https://x.org/f.tgz", "-o", "out.tgz")
    assert r["url"] == "https://x.org/f.tgz" and r["output"] == "out.tgz"


def test_curl_remote_name_uses_url_basename():
    r = P("curl", "-L", "-H", "Accept: x", "https://x.org/a/b.txt", "-O")
    assert r["url"] == "https://x.org/a/b.txt" and r["output"] == "b.txt"


def test_curl_remote_name_without_a_path_falls_back():
    assert P("curl", "-O", "https://x.org/")["output"] == "index.html"


def test_curl_long_output_forms():
    assert P("curl", "--output", "o", "https://h/p")["output"] == "o"
    assert P("curl", "--output=o", "https://h/p")["output"] == "o"


def test_curl_no_output_means_stdout():
    r = P("curl", "https://x.org/")
    assert r["url"] == "https://x.org/" and r["output"] is None


def test_curl_url_option():
    assert P("curl", "--url", "https://h/p")["url"] == "https://h/p"


def test_curl_skips_option_arguments():
    r = P("curl", "-d", "a=b", "-X", "POST", "https://h/p")
    assert r["url"] == "https://h/p"


def test_curl_bare_host_is_a_url():
    assert P("curl", "example.com/file")["url"] == "example.com/file"


