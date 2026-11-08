"""anim frames: the one-line animation frames and the player."""
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
anim = frames_mod        # constants and functions live in frames.py
operands = _load("operands")

ANSI = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]")


def plain(s):
    return ANSI.sub("", s)


# ---- build_frames --------------------------------------------------------- #

def frames(cmd, *args, ok=True, elapsed=0.0, ascii_only=False, width=80):
    info = operands.parse_operands(cmd, list(args))
    return anim.build_frames(cmd, info, ok, elapsed, ascii_only=ascii_only, width=width)


def test_unknown_command_has_no_frames():
    assert frames("ls", "-l") == []


@pytest.mark.parametrize("cmd,args", [
    ("mv", ("a.txt", "docs/")), ("cp", ("a.txt", "b.txt")), ("rm", ("a.txt",)),
    ("chmod", ("755", "a.txt")), ("rsync", ("-a", "src/", "dst/")),
    ("curl", ("-o", "f.bin", "https://x.org/f")),
])
def test_every_command_animates_with_a_distinct_final_frame(cmd, args):
    fs = frames(cmd, *args)
    assert len(fs) >= 3
    assert all(isinstance(f, str) and "\n" not in f for f in fs)
    assert plain(fs[0]) != plain(fs[-1])


def test_success_final_frame_has_check_and_names():
    last = plain(frames("mv", "report.txt", "docs/")[-1])
    assert anim.ICON_OK in last
    assert anim.ICON_FAIL not in last
    assert "report.txt" in last and "docs/" in last


def test_failure_final_frame_has_cross():
    last = plain(frames("mv", "report.txt", "docs/", ok=False)[-1])
    assert anim.ICON_FAIL in last
    assert anim.ICON_OK not in last


def test_many_sources_are_counted():
    assert "3 files" in plain(frames("mv", "a", "b", "c", "dir/")[-1])
    assert "3 files" in plain(frames("rm", "a", "b", "c")[-1])
    assert "2 files" in plain(frames("chmod", "644", "a", "b")[-1])


def test_chmod_shows_mode_and_file():
    last = plain(frames("chmod", "755", "run.sh")[-1])
    assert "755" in last and "run.sh" in last


def test_rm_shows_the_file_name():
    assert "old.log" in plain(frames("rm", "old.log")[-1])


@pytest.mark.parametrize("cmd,args", [
    ("rsync", ("-a", "src/", "dst/")),
    ("curl", ("-o", "f.bin", "https://x.org/f")),
])
def test_slow_commands_show_elapsed_time(cmd, args):
    assert "1.5s" in plain(frames(cmd, *args, elapsed=1.5)[-1])


def test_instant_commands_do_not_show_elapsed_time():
    assert not re.search(r"\d\.\ds", plain(frames("mv", "a", "b", elapsed=0.0)[-1]))


def test_curl_shows_output_name_or_stdout():
    assert "f.bin" in plain(frames("curl", "-o", "f.bin", "https://x.org/f")[-1])
    assert "stdout" in plain(frames("curl", "https://x.org/f")[-1])


def test_rsync_shows_source_and_destination():
    last = plain(frames("rsync", "-a", "src/", "host:dst/")[-1])
    assert "src/" in last and "host:dst/" in last


def test_ascii_mode_is_pure_ascii():
    for cmd, args in [("mv", ("a", "b")), ("cp", ("a", "b")), ("rm", ("a",)),
                      ("chmod", ("755", "a")), ("rsync", ("-a", "s/", "d/")),
                      ("curl", ("-o", "f", "https://x.org/f"))]:
        for ok in (True, False):
            for f in frames(cmd, *args, ok=ok, ascii_only=True):
                assert all(ord(c) < 128 for c in f), (cmd, ok, f)
    assert anim.ASCII_OK in plain(frames("mv", "a", "b", ascii_only=True)[-1])
    assert anim.ASCII_FAIL in plain(frames("mv", "a", "b", ok=False, ascii_only=True)[-1])


def test_nerd_mode_uses_private_use_glyphs():
    joined = "".join(frames("mv", "a", "b"))
    assert any(0xE000 <= ord(c) <= 0xF8FF or ord(c) >= 0xF0000 for c in joined)


@pytest.mark.parametrize("ascii_only", [False, True])
def test_long_names_are_truncated_to_the_width(ascii_only):
    long = "x" * 200
    for f in frames("mv", long, "y" * 200, ascii_only=ascii_only, width=60):
        assert len(plain(f)) <= 59


def test_frames_fit_a_narrow_terminal():
    for f in frames("rsync", "-a", "a-fairly-long-source-name/", "host:a-long-destination/", width=40):
        assert len(plain(f)) <= 39


# ---- play ----------------------------------------------------------------- #

class Sink:
    def __init__(self):
        self.parts = []

    def write(self, s):
        self.parts.append(s)

    def flush(self):
        pass

    def text(self):
        return "".join(self.parts)


def test_play_redraws_the_line_and_ends_with_a_newline():
    out = Sink()
    anim.play(["one", "two", "three"], out, 0)
    text = out.text()
    assert text.endswith("\n")
    assert text.count("\n") == 1
    assert text.count("\r") >= 3
    assert "one" in text and "two" in text and text.rstrip("\n").endswith("three")


def test_play_with_no_frames_writes_nothing():
    out = Sink()
    anim.play([], out, 0)
    assert out.text() == ""


