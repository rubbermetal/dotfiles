"""anim command line: runs the real command, then animates the result on a terminal."""
import os
import pathlib
import pty
import re
import select
import subprocess
import sys

import pytest

ROOT = pathlib.Path(__file__).resolve().parent.parent
SHARE = ROOT / ".local" / "share" / "anim"
LAUNCHER = ROOT / ".local" / "bin" / "anim"
sys.path.insert(0, str(SHARE))

import frames as anim            # ICON_OK, ICON_FAIL, ASCII_OK, ASCII_FAIL  # noqa: E402

ANSI = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]")


def plain(s):
    return ANSI.sub("", s)


# ---- command line --------------------------------------------------------- #

def env(**extra):
    e = dict(os.environ)
    for k in ("ANIM", "ANIM_ASCII", "ANIM_DELAY"):
        e.pop(k, None)
    e.update({"TERM": "xterm-256color", "LC_ALL": "C.UTF-8", "PYTHONIOENCODING": "utf-8", "ANIM_DELAY": "0"})
    e.update(extra)
    return e


def run_plain(*argv, input=None, **extra):
    return subprocess.run([sys.executable, str(LAUNCHER), *argv], capture_output=True, text=True,
                          input=input, env=env(**extra), timeout=30)


def run_pty(*argv, cwd=None, **extra):
    """Run the launcher with a real terminal as stdout/stderr. Returns (exit code, output text)."""
    master, slave = pty.openpty()
    proc = subprocess.Popen([sys.executable, str(LAUNCHER), *argv], stdin=subprocess.DEVNULL,
                            stdout=slave, stderr=slave, env=env(**extra), cwd=cwd, close_fds=True)
    os.close(slave)
    chunks = []
    while True:
        ready, _, _ = select.select([master], [], [], 30)
        if not ready:
            proc.kill()
            break
        try:
            data = os.read(master, 4096)
        except OSError:
            break
        if not data:
            break
        chunks.append(data)
    os.close(master)
    code = proc.wait(timeout=30)
    return code, b"".join(chunks).decode("utf-8", errors="replace")


def test_no_arguments_prints_usage_and_exits_2():
    r = run_plain()
    assert r.returncode == 2
    assert "usage" in r.stderr.lower()


def test_not_a_tty_is_a_pure_passthrough():
    r = run_plain("sh", "-c", "echo hi; echo err >&2; exit 3")
    assert r.returncode == 3
    assert r.stdout == "hi\n" and r.stderr == "err\n"


def test_stdin_reaches_the_command():
    r = run_plain("sh", "-c", "read x; echo got:$x", input="hello\n")
    assert r.stdout == "got:hello\n"


def test_command_not_found_returns_127():
    r = run_plain("definitely-not-a-command-xyz")
    assert r.returncode == 127
    assert "not found" in r.stderr.lower()


def test_launcher_works_through_a_symlink(tmp_path):
    link = tmp_path / "anim"
    link.symlink_to(LAUNCHER)
    r = subprocess.run([sys.executable, str(link), "sh", "-c", "echo via-link"], capture_output=True,
                       text=True, env=env(), timeout=30)
    assert r.returncode == 0 and r.stdout == "via-link\n"


def test_tty_unknown_command_is_not_animated():
    code, out = run_pty("echo", "hello")
    assert code == 0
    assert "\x1b" not in out and out.strip() == "hello"


def test_tty_exit_code_passthrough_for_unknown_command():
    code, _ = run_pty("sh", "-c", "exit 7")
    assert code == 7


def test_tty_mv_moves_the_file_and_animates(tmp_path):
    (tmp_path / "a").write_text("x")
    code, out = run_pty("mv", "a", "b", cwd=tmp_path)
    assert code == 0
    assert (tmp_path / "b").exists() and not (tmp_path / "a").exists()
    assert "\r" in out
    assert anim.ICON_OK in plain(out)
    assert "b" in plain(out)


def test_tty_cp_copies_the_file(tmp_path):
    (tmp_path / "a").write_text("x")
    code, out = run_pty("cp", "a", "b", cwd=tmp_path)
    assert code == 0 and (tmp_path / "a").exists() and (tmp_path / "b").read_text() == "x"
    assert anim.ICON_OK in plain(out)


def test_tty_rm_removes_the_file(tmp_path):
    (tmp_path / "a").write_text("x")
    code, out = run_pty("rm", "a", cwd=tmp_path)
    assert code == 0 and not (tmp_path / "a").exists()
    assert anim.ICON_OK in plain(out)


def test_tty_chmod_changes_the_mode(tmp_path):
    f = tmp_path / "a"
    f.write_text("x")
    f.chmod(0o644)
    code, out = run_pty("chmod", "600", "a", cwd=tmp_path)
    assert code == 0 and (f.stat().st_mode & 0o777) == 0o600
    assert anim.ICON_OK in plain(out) and "600" in plain(out)


def test_tty_failure_keeps_the_error_and_shows_a_cross(tmp_path):
    code, out = run_pty("mv", "missing", "b", cwd=tmp_path)
    assert code == 1
    assert "No such file" in out
    assert anim.ICON_FAIL in plain(out)
    assert anim.ICON_OK not in plain(out)


def test_anim_off_gives_the_plain_command_output(tmp_path):
    (tmp_path / "a").write_text("x")
    code, out = run_pty("mv", "-v", "a", "b", cwd=tmp_path, ANIM="0")
    assert code == 0 and (tmp_path / "b").exists()
    assert "\x1b" not in out
    assert anim.ICON_OK not in out and anim.ASCII_OK not in out
    assert "renamed" in out


@pytest.mark.parametrize("extra", [{"TERM": "linux"}, {"ANIM_ASCII": "1"}])
def test_console_and_ascii_switch_use_plain_ascii(tmp_path, extra):
    (tmp_path / "a").write_text("x")
    code, out = run_pty("mv", "a", "b", cwd=tmp_path, **extra)
    assert code == 0
    assert all(ord(c) < 128 for c in out), repr(out)
    assert anim.ASCII_OK in plain(out)


def _fake_bin(tmp_path, name, body):
    bindir = tmp_path / "fakebin"
    bindir.mkdir(exist_ok=True)
    script = bindir / name
    script.write_text("#!/bin/sh\n" + body + "\n")
    script.chmod(0o755)
    return str(bindir)


def test_tty_curl_passthrough_and_summary(tmp_path):
    bindir = _fake_bin(tmp_path, "curl", 'echo fake-curl "$@"; sleep 0.2; : > out.bin')
    code, out = run_pty("curl", "-o", "out.bin", "https://x.test/f", cwd=tmp_path,
                        PATH=bindir + os.pathsep + os.environ["PATH"])
    assert code == 0
    assert "fake-curl" in out
    p = plain(out)
    assert "out.bin" in p and anim.ICON_OK in p
    assert re.search(r"\d+\.\ds", p)


def test_tty_rsync_summary(tmp_path):
    bindir = _fake_bin(tmp_path, "rsync", "sleep 0.2")
    code, out = run_pty("rsync", "-a", "src/", "dst/", cwd=tmp_path,
                        PATH=bindir + os.pathsep + os.environ["PATH"])
    assert code == 0
    p = plain(out)
    assert "src/" in p and "dst/" in p and anim.ICON_OK in p
    assert re.search(r"\d+\.\ds", p)


def test_tty_failing_slow_command_exit_code_and_cross(tmp_path):
    bindir = _fake_bin(tmp_path, "rsync", "echo boom >&2; exit 23")
    code, out = run_pty("rsync", "-a", "src/", "dst/", cwd=tmp_path,
                        PATH=bindir + os.pathsep + os.environ["PATH"])
    assert code == 23
    assert "boom" in out
    assert anim.ICON_FAIL in plain(out)
