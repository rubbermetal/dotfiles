"""Shell glue for anim: aliases/{mv,cp,rm,chmod,rsync,curl}.sh in bash and in zsh (sh emulation).

Each file removes the old alias, keeps the old flags, and defines a function that calls `anim`
only for an interactive terminal (stdout is a tty, ANIM is not 0, anim is installed).
"""
import os
import pathlib
import pty
import re
import select
import shutil
import subprocess

import pytest

ROOT = pathlib.Path(__file__).resolve().parent.parent
ALIASES = ROOT / ".config" / "bash.d" / "aliases"
BIN = ROOT / ".local" / "bin"
NAMES = ["mv", "cp", "rm", "chmod", "rsync", "curl"]
ANSI = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]")

SHELLS = [
    pytest.param(["bash", "-c"], id="bash"),
    pytest.param(["zsh", "--emulate", "sh", "-c"], id="zsh-sh"),
]


def env(**extra):
    e = dict(os.environ)
    for k in ("ANIM", "ANIM_ASCII", "ANIM_DELAY"):
        e.pop(k, None)
    e.update({"TERM": "xterm-256color", "LC_ALL": "C.UTF-8", "ANIM_DELAY": "0"})
    e["PATH"] = str(BIN) + os.pathsep + e["PATH"]
    e.update(extra)
    return e


def sh(shell, script, cwd, input=None, **extra):
    return subprocess.run(shell + [script], cwd=cwd, capture_output=True, text=True, input=input,
                          env=env(**extra), timeout=60)


def sh_pty(shell, script, cwd, **extra):
    master, slave = pty.openpty()
    proc = subprocess.Popen(shell + [script], cwd=cwd, stdin=subprocess.DEVNULL, stdout=slave,
                            stderr=slave, env=env(**extra), close_fds=True)
    os.close(slave)
    chunks = []
    while True:
        ready, _, _ = select.select([master], [], [], 60)
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
    code = proc.wait(timeout=60)
    return code, ANSI.sub("", b"".join(chunks).decode("utf-8", errors="replace"))


def src(name):
    return f'. "{ALIASES / (name + ".sh")}"'


# ---- the files themselves ------------------------------------------------- #

@pytest.mark.parametrize("name", NAMES)
def test_alias_file_exists_and_has_usage_comment(name):
    text = (ALIASES / f"{name}.sh").read_text()
    assert "ANIM=0" in text                       # how to turn it off is documented in the file


@pytest.mark.parametrize("name", NAMES)
def test_alias_file_parses_the_way_the_loader_checks_it(name):
    f = str(ALIASES / f"{name}.sh")
    assert subprocess.run(["bash", "-n", f]).returncode == 0
    assert subprocess.run(["zsh", "-n", f]).returncode == 0
    assert subprocess.run(["zsh", "--emulate", "sh", "-n", f]).returncode == 0


@pytest.mark.parametrize("name", NAMES)
@pytest.mark.parametrize("shell", SHELLS)
def test_sourcing_defines_a_function_not_an_alias(shell, name, tmp_path):
    r = sh(shell, f'{src(name)}; type {name}', tmp_path)
    assert r.returncode == 0, r.stderr
    assert "function" in r.stdout.lower()
    assert "is an alias" not in r.stdout.lower()


@pytest.mark.parametrize("name", NAMES)
@pytest.mark.parametrize("shell", SHELLS)
def test_an_existing_alias_is_replaced_without_error(shell, name, tmp_path):
    r = sh(shell, f"alias {name}='echo OLD-ALIAS'; {src(name)}; type {name}", tmp_path)
    assert "function" in r.stdout.lower()
    assert "defining function based on alias" not in r.stderr


@pytest.mark.parametrize("name", ["rsync", "curl"])
@pytest.mark.parametrize("shell", SHELLS)
def test_no_function_when_the_program_is_missing(shell, name, tmp_path):
    empty = tmp_path / "empty"
    empty.mkdir()
    argv = [shutil.which(shell[0])] + shell[1:] + [f'{src(name)}; type {name}']   # absolute shell path: PATH is empty below
    r = subprocess.run(argv, cwd=tmp_path, capture_output=True, text=True,
                       env={"PATH": str(empty), "HOME": str(tmp_path)}, timeout=30)
    assert "function" not in r.stdout.lower()


# ---- old flags are preserved when not on a terminal ------------------------ #

@pytest.mark.parametrize("shell", SHELLS)
def test_mv_keeps_verbose_and_interactive_flags(shell, tmp_path):
    (tmp_path / "a").write_text("A")
    r = sh(shell, f"{src('mv')}; mv a b", tmp_path)
    assert r.returncode == 0 and "renamed" in r.stdout
    (tmp_path / "c").write_text("C")
    r = sh(shell, f"{src('mv')}; mv c b", tmp_path, input="n\n")          # -i asks, we say no
    assert (tmp_path / "b").read_text() == "A" and (tmp_path / "c").exists()


@pytest.mark.parametrize("shell", SHELLS)
def test_cp_keeps_verbose_interactive_and_preserve_flags(shell, tmp_path):
    (tmp_path / "a").write_text("A")
    r = sh(shell, f"{src('cp')}; cp a b", tmp_path)
    assert r.returncode == 0 and "'a' -> 'b'" in r.stdout
    (tmp_path / "c").write_text("C")
    sh(shell, f"{src('cp')}; cp c b", tmp_path, input="n\n")
    assert (tmp_path / "b").read_text() == "A"


@pytest.mark.parametrize("shell", SHELLS)
def test_rm_removes_files(shell, tmp_path):
    (tmp_path / "a").write_text("A")
    r = sh(shell, f"{src('rm')}; rm a", tmp_path)
    assert r.returncode == 0 and not (tmp_path / "a").exists()


@pytest.mark.parametrize("name,flags", [
    ("mv", ["-vi"]), ("cp", ["-vip"]), ("rm", ["-I", "--preserve-root"]), ("chmod", ["-v", "--preserve-root"]),
])
def test_old_alias_flags_are_still_in_the_file(name, flags):
    text = (ALIASES / f"{name}.sh").read_text()
    for flag in flags:
        assert re.search(r"(?<![\w-])" + re.escape(flag) + r"(?![\w-])", text), (name, flag)


@pytest.mark.parametrize("shell", SHELLS)
def test_chmod_keeps_verbose_flag(shell, tmp_path):
    f = tmp_path / "a"
    f.write_text("A")
    f.chmod(0o644)
    r = sh(shell, f"{src('chmod')}; chmod 600 a", tmp_path)
    assert r.returncode == 0 and "changed from" in r.stdout
    assert (f.stat().st_mode & 0o777) == 0o600


@pytest.mark.parametrize("shell", SHELLS)
def test_rsync_passthrough(shell, tmp_path):
    (tmp_path / "src").mkdir()
    (tmp_path / "src" / "f").write_text("F")
    r = sh(shell, f"{src('rsync')}; rsync -a src/ dst/", tmp_path)
    assert r.returncode == 0 and (tmp_path / "dst" / "f").read_text() == "F"


@pytest.mark.parametrize("shell", SHELLS)
def test_curl_passthrough_and_piping(shell, tmp_path):
    (tmp_path / "page").write_text("hello-curl")
    r = sh(shell, f"{src('curl')}; curl -s file://{tmp_path}/page | cat", tmp_path)
    assert r.stdout == "hello-curl"


@pytest.mark.parametrize("name", NAMES)
@pytest.mark.parametrize("shell", SHELLS)
def test_exit_status_is_preserved(shell, name, tmp_path):
    cmd = {"mv": "mv nope1 nope2", "cp": "cp nope1 nope2", "rm": "rm nope1", "chmod": "chmod 600 nope1",
           "rsync": "rsync nope1 nope2/", "curl": "curl -s file:///nonexistent-xyz"}[name]
    r = sh(shell, f"{src(name)}; {cmd}", tmp_path)
    ref = subprocess.run(["sh", "-c", cmd], cwd=tmp_path, capture_output=True, text=True)
    assert r.returncode == ref.returncode != 0, (name, r.returncode, ref.returncode)


# ---- on a terminal the function uses anim ---------------------------------- #

@pytest.mark.parametrize("shell", SHELLS)
def test_mv_on_a_terminal_is_animated(shell, tmp_path):
    (tmp_path / "a").write_text("A")
    code, out = sh_pty(shell, f"{src('mv')}; mv a b", tmp_path)
    assert code == 0 and (tmp_path / "b").exists()
    assert "" in out                          # the Nerd Font check mark from anim
    assert "renamed" in out                         # mv -v output still shown


@pytest.mark.parametrize("shell", SHELLS)
def test_anim_zero_turns_it_off_on_a_terminal(shell, tmp_path):
    (tmp_path / "a").write_text("A")
    code, out = sh_pty(shell, f"{src('mv')}; mv a b", tmp_path, ANIM="0")
    assert code == 0 and (tmp_path / "b").exists()
    assert "" not in out and "[ok]" not in out
    assert "renamed" in out


@pytest.mark.parametrize("shell", SHELLS)
def test_without_anim_installed_the_command_still_works_on_a_terminal(shell, tmp_path):
    (tmp_path / "a").write_text("A")
    clean = [p for p in os.environ["PATH"].split(os.pathsep) if p != str(BIN)]
    e = env()
    e["PATH"] = os.pathsep.join(p for p in clean if not os.path.exists(os.path.join(p, "anim")))
    master, slave = pty.openpty()
    proc = subprocess.Popen(shell + [f"{src('mv')}; mv a b"], cwd=tmp_path, stdin=subprocess.DEVNULL,
                            stdout=slave, stderr=slave, env=e, close_fds=True)
    os.close(slave)
    out = b""
    while True:
        try:
            d = os.read(master, 4096)
        except OSError:
            break
        if not d:
            break
        out += d
    os.close(master)
    assert proc.wait(timeout=30) == 0
    assert (tmp_path / "b").exists()
