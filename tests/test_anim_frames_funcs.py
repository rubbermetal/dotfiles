"""anim result lines for shell functions: trash, extract, mkcd, mvg, cpg and the chmod helpers (frames_funcs.py)."""
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


frames_mod = _load("frames")
funcs = _load("frames_funcs")
ANSI = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]")
ALL = ["trash", "trashempty", "extract", "mkcd", "mvg", "cpg", "chmodfix", "chmodcopy", "chmoddirs", "chmodfiles"]
SAMPLE = {
    "trash": ["a.txt"], "trashempty": [], "extract": ["a.tgz", "out"], "mkcd": ["new/dir"], "mvg": ["a", "b"],
    "cpg": ["a", "b"], "chmodfix": ["web"], "chmodcopy": ["ref", "x"], "chmoddirs": ["755", "web"], "chmodfiles": ["644", "web"],
}


def plain(s):
    return ANSI.sub("", s)


def build(name, args, ok=True, ascii_only=False, width=80):
    return funcs.build_result(name, funcs.parse_result(name, args), ok, ascii_only=ascii_only, width=width)


def test_names_are_the_ten_functions():
    assert sorted(funcs.NAMES) == sorted(ALL)


# ---- parse_result ---------------------------------------------------------- #

def test_parse_trash_drops_flags():
    assert funcs.parse_result("trash", ["-f", "a", "b"]) == {"sources": ["a", "b"], "dest": None, "mode": None}


def test_parse_trashempty_has_nothing():
    assert funcs.parse_result("trashempty", []) == {"sources": [], "dest": None, "mode": None}


def test_parse_extract_default_and_given_target():
    assert funcs.parse_result("extract", ["a.tgz"]) == {"sources": ["a.tgz"], "dest": ".", "mode": None}
    assert funcs.parse_result("extract", ["a.tgz", "out"]) == {"sources": ["a.tgz"], "dest": "out", "mode": None}


def test_parse_extract_without_args_is_empty():
    assert funcs.parse_result("extract", [])["sources"] == []


def test_parse_mkcd():
    assert funcs.parse_result("mkcd", ["d/e"]) == {"sources": ["d/e"], "dest": None, "mode": None}


@pytest.mark.parametrize("name", ["mvg", "cpg"])
def test_parse_last_argument_is_destination(name):
    assert funcs.parse_result(name, ["a", "b", "dir"]) == {"sources": ["a", "b"], "dest": "dir", "mode": None}


@pytest.mark.parametrize("name", ["mvg", "cpg"])
def test_parse_one_argument_has_no_sources(name):
    assert funcs.parse_result(name, ["a"])["sources"] == []


def test_parse_chmodfix_defaults_to_here():
    assert funcs.parse_result("chmodfix", []) == {"sources": ["."], "dest": None, "mode": None}
    assert funcs.parse_result("chmodfix", ["web"]) == {"sources": ["web"], "dest": None, "mode": None}


def test_parse_chmodcopy_first_is_the_reference():
    assert funcs.parse_result("chmodcopy", ["ref", "x", "y"]) == {"sources": ["x", "y"], "dest": None, "mode": "ref"}


@pytest.mark.parametrize("name", ["chmoddirs", "chmodfiles"])
def test_parse_chmod_tree_helpers(name):
    assert funcs.parse_result(name, ["-y", "755", "a", "b"]) == {"sources": ["a", "b"], "dest": None, "mode": "755"}
    assert funcs.parse_result(name, ["--yes", "755"]) == {"sources": ["."], "dest": None, "mode": "755"}


@pytest.mark.parametrize("name", ["chmoddirs", "chmodfiles"])
def test_parse_chmod_tree_helpers_without_a_mode_is_empty(name):
    assert funcs.parse_result(name, ["-y"]) == {"sources": [], "dest": None, "mode": None}


def test_parse_unknown_name_is_empty():
    assert funcs.parse_result("ls", ["a"]) == {"sources": [], "dest": None, "mode": None}


# ---- build_result ---------------------------------------------------------- #

@pytest.mark.parametrize("name", ALL)
def test_frame_count_and_only_the_last_has_the_mark(name):
    fr = build(name, SAMPLE[name], ascii_only=True)
    assert len(fr) == frames_mod.STEPS + 1
    assert "[ok]" in plain(fr[-1])
    assert not any("[ok]" in plain(f) or "[x]" in plain(f) for f in fr[:-1])


@pytest.mark.parametrize("name", ALL)
def test_failure_shows_the_failure_mark(name):
    fr = build(name, SAMPLE[name], ok=False, ascii_only=True)
    assert "[x]" in plain(fr[-1]) and "[ok]" not in plain(fr[-1])


@pytest.mark.parametrize("name", ALL)
def test_frames_fit_the_width_even_with_long_names(name):
    long = "x" * 300
    args = {"trash": [long], "trashempty": [], "extract": [long, long], "mkcd": [long], "mvg": [long, long], "cpg": [long, long],
            "chmodfix": [long], "chmodcopy": [long, long], "chmoddirs": ["755", long], "chmodfiles": ["644", long]}[name]
    for f in build(name, args, ascii_only=True, width=60):
        assert len(plain(f)) < 60


@pytest.mark.parametrize("name", ALL)
def test_ascii_mode_has_only_ascii(name):
    for f in build(name, SAMPLE[name], ascii_only=True):
        assert plain(f).isascii()


@pytest.mark.parametrize("name,icon", [("trash", "trash"), ("trashempty", "trash"), ("extract", "folder_open"), ("mkcd", "folder_open"),
                                       ("mvg", "file"), ("cpg", "copy"), ("chmodfix", "lock"), ("chmodcopy", "lock"),
                                       ("chmoddirs", "lock"), ("chmodfiles", "lock")])
def test_each_uses_its_icon(name, icon):
    assert frames_mod.ICONS[icon] in plain(build(name, SAMPLE[name])[-1])


def test_names_shown():
    assert "a.txt" in plain(build("trash", ["a.txt"])[-1])
    assert "Trash" in plain(build("trashempty", [])[-1])
    last = plain(build("extract", ["a.tgz", "out"])[-1])
    assert "a.tgz" in last and "out" in last
    assert "new/dir" in plain(build("mkcd", ["new/dir"])[-1])
    last = plain(build("mvg", ["one", "two"])[-1])
    assert "one" in last and "two" in last
    last = plain(build("cpg", ["a", "b", "dir"])[-1])
    assert "2 files" in last and "dir" in last
    assert "web" in plain(build("chmodfix", ["web"])[-1])
    last = plain(build("chmodcopy", ["ref", "x"])[-1])
    assert "ref" in last and "x" in last
    last = plain(build("chmoddirs", ["755", "web"])[-1])
    assert "755" in last and "web" in last


@pytest.mark.parametrize("name,args", [("trash", []), ("extract", []), ("mkcd", []), ("mvg", ["a"]), ("cpg", ["a"]),
                                       ("chmodcopy", ["ref"]), ("chmoddirs", []), ("ls", ["a"])])
def test_nothing_to_show_gives_no_frames(name, args):
    assert build(name, args) == []
