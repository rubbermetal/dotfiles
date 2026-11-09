"""anim operands for ln, mkdir, chown, chgrp, shred, wget and umount (operands_more.py)."""
import importlib.util
import pathlib
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


more = _load("operands_more")
operands = _load("operands")


def P(cmd, *args):
    return more.parse_more(cmd, list(args))


def test_unknown_command_returns_none():
    assert P("ls", "-l") is None
    assert P("mv", "a", "b") is None          # mv/cp/rm/chmod/rsync/curl belong to operands.py


def test_result_has_all_keys():
    r = P("ln", "-s", "target", "link")
    assert set(r) == {"sources", "dest", "mode", "url", "output"}


def test_operands_dispatches_to_the_new_parsers():
    r = operands.parse_operands("mkdir", ["-vp", "a/b"])
    assert r["sources"] == ["a/b"]
    assert operands.parse_operands("ls", ["-l"])["sources"] == []           # still empty for unknown commands


# ---- ln ------------------------------------------------------------------- #

def test_ln_target_and_link_name():
    r = P("ln", "-s", "target", "link")
    assert r["sources"] == ["target"] and r["dest"] == "link"


def test_ln_interactive_flag_is_ignored():
    r = P("ln", "-i", "-s", "/a/b", "c")
    assert r["sources"] == ["/a/b"] and r["dest"] == "c"


def test_ln_single_operand_links_into_the_current_directory_by_basename():
    r = P("ln", "-s", "/some/dir/file.txt")
    assert r["sources"] == ["/some/dir/file.txt"] and r["dest"] == "file.txt"
    assert P("ln", "/some/dir/")["dest"] == "dir"


def test_ln_target_directory_option():
    r = P("ln", "-s", "-t", "dir", "a", "b")
    assert r["sources"] == ["a", "b"] and r["dest"] == "dir"
    r = P("ln", "--target-directory=dir", "a")
    assert r["sources"] == ["a"] and r["dest"] == "dir"


def test_ln_double_dash():
    r = P("ln", "-s", "--", "-odd", "name")
    assert r["sources"] == ["-odd"] and r["dest"] == "name"


# ---- mkdir ---------------------------------------------------------------- #

def test_mkdir_collects_directories():
    r = P("mkdir", "-vp", "a", "b/c")
    assert r["sources"] == ["a", "b/c"] and r["dest"] is None and r["mode"] is None


def test_mkdir_mode_option_is_not_a_directory():
    r = P("mkdir", "-m", "755", "-p", "a")
    assert r["sources"] == ["a"] and r["mode"] == "755"
    r = P("mkdir", "--mode=700", "a")
    assert r["sources"] == ["a"] and r["mode"] == "700"


# ---- chown / chgrp ---------------------------------------------------------- #

@pytest.mark.parametrize("cmd,spec", [("chown", "root:root"), ("chgrp", "staff")])
def test_owner_spec_is_the_mode_field_and_files_follow(cmd, spec):
    r = P(cmd, "--preserve-root", "-R", spec, "a", "b")
    assert r["mode"] == spec and r["sources"] == ["a", "b"]


@pytest.mark.parametrize("cmd", ["chown", "chgrp"])
def test_owner_reference_has_no_spec(cmd):
    r = P(cmd, "--reference=ref", "f")
    assert r["mode"] is None and r["sources"] == ["f"]
    r = P(cmd, "--reference", "ref", "f")
    assert r["mode"] is None and r["sources"] == ["f"]


def test_chown_verbose_flags_before_spec():
    r = P("chown", "-v", "-h", "me", "file")
    assert r["mode"] == "me" and r["sources"] == ["file"]


# ---- shred ---------------------------------------------------------------- #

def test_shred_collects_files_and_skips_option_values():
    r = P("shred", "--force", "--remove", "--verbose", "-n", "3", "a", "b")
    assert r["sources"] == ["a", "b"]
    r = P("shred", "--iterations=5", "a")
    assert r["sources"] == ["a"]


# ---- wget ----------------------------------------------------------------- #

def test_wget_url_and_default_output_name():
    r = P("wget", "-c", "https://x.org/a/file.tgz")
    assert r["url"] == "https://x.org/a/file.tgz" and r["output"] == "file.tgz"


def test_wget_output_document_option():
    r = P("wget", "-O", "out.bin", "https://x.org/f")
    assert r["output"] == "out.bin"
    r = P("wget", "--output-document=out.bin", "https://x.org/f")
    assert r["output"] == "out.bin"


def test_wget_output_to_stdout_has_no_name():
    assert P("wget", "-O", "-", "https://x.org/f")["output"] is None


def test_wget_directory_prefix_is_part_of_the_output():
    r = P("wget", "-P", "/home/me/Downloads", "https://x.org/a/file.tgz")
    assert r["output"] == "/home/me/Downloads/file.tgz"
    r = P("wget", "--directory-prefix=dl/", "https://x.org/file.tgz")
    assert r["output"] == "dl/file.tgz"


def test_wget_url_without_a_path_uses_index_html():
    assert P("wget", "https://x.org/")["output"] == "index.html"
    assert P("wget", "https://x.org")["output"] == "index.html"


def test_wget_query_and_fragment_are_dropped_from_the_name():
    assert P("wget", "https://x.org/a/b.txt?x=1#f")["output"] == "b.txt"


def test_wget_skips_option_values():
    r = P("wget", "--header", "Accept: x", "-t", "3", "https://x.org/f.txt")
    assert r["url"] == "https://x.org/f.txt" and r["output"] == "f.txt"


def test_wget_without_a_url():
    r = P("wget", "-i", "list.txt")
    assert r["url"] is None and r["output"] is None


# ---- umount ---------------------------------------------------------------- #

def test_umount_collects_mount_points():
    r = P("umount", "-l", "/mnt/usb", "/mnt/disk")
    assert r["sources"] == ["/mnt/usb", "/mnt/disk"]
    r = P("umount", "-t", "ext4", "/mnt/usb")
    assert r["sources"] == ["/mnt/usb"]
