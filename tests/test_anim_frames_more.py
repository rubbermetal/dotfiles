"""anim frames for ln, mkdir, chown, chgrp, shred, wget and umount (frames_more.py)."""
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
more = _load("frames_more")
operands = _load("operands")

ANSI = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]")


def plain(s):
    return ANSI.sub("", s)


NEW = ["ln", "mkdir", "chown", "chgrp", "shred", "wget", "umount"]


def info_for(cmd, *args):
    return operands.parse_operands(cmd, list(args))


def frames(cmd, *args, ok=True, elapsed=0.0, ascii_only=False, width=80):
    return frames_mod.build_frames(cmd, info_for(cmd, *args), ok, elapsed, ascii_only=ascii_only, width=width)


CASES = {
    "ln": ("-s", "target.txt", "link.txt"),
    "mkdir": ("-vp", "new/dir"),
    "chown": ("me:me", "a.txt"),
    "chgrp": ("staff", "a.txt"),
    "shred": ("--force", "--remove", "secret.txt"),
    "wget": ("-c", "https://x.org/f.tgz"),
    "umount": ("/mnt/usb",),
}


def test_new_icons_exist():
    for key in ("link", "folder_open", "user", "users", "fire", "eject"):
        assert key in frames_mod.ICONS


def test_unknown_command_gives_no_frames_through_both_paths():
    assert more.build_more("ls", {"sources": [], "dest": None, "mode": None, "url": None, "output": None},
                           True, 0.0, False, 80) == []
    assert frames("ls", "-l") == []


@pytest.mark.parametrize("cmd", NEW)
def test_every_new_command_animates_with_a_distinct_final_frame(cmd):
    fs = frames(cmd, *CASES[cmd])
    assert len(fs) >= 3
    assert all(isinstance(f, str) and "\n" not in f for f in fs)
    assert plain(fs[0]) != plain(fs[-1])


@pytest.mark.parametrize("cmd", NEW)
def test_success_and_failure_marks(cmd):
    ok = plain(frames(cmd, *CASES[cmd])[-1])
    bad = plain(frames(cmd, *CASES[cmd], ok=False)[-1])
    assert frames_mod.ICON_OK in ok and frames_mod.ICON_FAIL not in ok
    assert frames_mod.ICON_FAIL in bad and frames_mod.ICON_OK not in bad


@pytest.mark.parametrize("cmd", NEW)
def test_ascii_mode_is_pure_ascii(cmd):
    for ok in (True, False):
        for f in frames(cmd, *CASES[cmd], ok=ok, ascii_only=True):
            assert all(ord(c) < 128 for c in f), (cmd, f)
    assert frames_mod.ASCII_OK in plain(frames(cmd, *CASES[cmd], ascii_only=True)[-1])


@pytest.mark.parametrize("cmd", NEW)
def test_nerd_mode_uses_private_use_glyphs(cmd):
    joined = "".join(frames(cmd, *CASES[cmd]))
    assert any(0xE000 <= ord(c) <= 0xF8FF or ord(c) >= 0xF0000 for c in joined)


@pytest.mark.parametrize("cmd", NEW)
@pytest.mark.parametrize("ascii_only", [False, True])
def test_long_names_are_truncated_to_the_width(cmd, ascii_only):
    long = "x" * 200
    args = {"ln": ("-s", long, long + "y"), "mkdir": (long,), "chown": ("o" * 50, long), "chgrp": ("g" * 50, long),
            "shred": (long,), "wget": ("https://x.org/" + long,), "umount": (long,)}[cmd]
    for f in frames(cmd, *args, ascii_only=ascii_only, width=60):
        assert len(plain(f)) <= 59, (cmd, len(plain(f)))


@pytest.mark.parametrize("cmd", NEW)
def test_frames_fit_a_narrow_terminal(cmd):
    for f in frames(cmd, *CASES[cmd], width=40, elapsed=12.3):
        assert len(plain(f)) <= 39


def test_ln_shows_target_and_link():
    last = plain(frames("ln", "-s", "target.txt", "link.txt")[-1])
    assert "target.txt" in last and "link.txt" in last


def test_mkdir_shows_the_directory_or_a_count():
    assert "new/dir" in plain(frames("mkdir", "-vp", "new/dir")[-1])
    assert "3 files" in plain(frames("mkdir", "a", "b", "c")[-1]) or "3 dirs" in plain(frames("mkdir", "a", "b", "c")[-1])


def test_chown_and_chgrp_show_owner_and_file():
    last = plain(frames("chown", "me:me", "a.txt")[-1])
    assert "me:me" in last and "a.txt" in last
    last = plain(frames("chgrp", "staff", "a.txt")[-1])
    assert "staff" in last and "a.txt" in last


def test_chown_reference_shows_ref():
    assert "ref" in plain(frames("chown", "--reference=x", "a.txt")[-1])


def test_shred_shows_the_file_struck_through():
    fs = frames("shred", "--force", "secret.txt")
    assert "secret.txt" in plain(fs[-1])
    assert any(frames_mod.STRIKE in f for f in fs)


def test_wget_shows_url_output_and_elapsed_time():
    last = plain(frames("wget", "-c", "https://x.org/f.tgz", elapsed=1.5)[-1])
    assert "https://x.org/f.tgz" in last and "f.tgz" in last and "1.5s" in last


def test_wget_without_an_output_name_says_stdout():
    assert "stdout" in plain(frames("wget", "-O", "-", "https://x.org/f.tgz")[-1])


def test_umount_shows_the_mount_point():
    last = plain(frames("umount", "/mnt/usb")[-1])
    assert "/mnt/usb" in last


def test_instant_new_commands_do_not_show_elapsed_time():
    for cmd in ("ln", "mkdir", "chown", "chgrp", "shred", "umount"):
        assert not re.search(r"\d\.\ds", plain(frames(cmd, *CASES[cmd], elapsed=2.5)[-1])), cmd
