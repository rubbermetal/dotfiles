"""The dotfiles' alias and function files must load in bash AND zsh (the loader skips a file zsh cannot parse).

BASH_ONLY files are allowed to fail in zsh, and the test below checks that they really do, so the
list cannot hide a file that was fixed or a new problem.
  addpath.sh  uses associative arrays, `read -a`, ${!var} and BASH_REMATCH (a real bash-only tool)
  repeat.sh   a function called `repeat`, a reserved word in zsh (zsh has its own: repeat 3 echo hi)
"""
import os
import pathlib
import subprocess

import pytest

ROOT = pathlib.Path(__file__).resolve().parent.parent
BASHD = ROOT / ".config" / "bash.d"
FUNCTIONS = sorted((BASHD / "functions").glob("*.sh"))
ALIASES = sorted((BASHD / "aliases").glob("*.sh"))
BASH_ONLY = {"addpath.sh", "repeat.sh"}

SHELLS = [
    pytest.param(["bash", "-c"], id="bash"),
    pytest.param(["zsh", "--emulate", "sh", "-c"], id="zsh-sh"),
]


def rc(*argv):
    return subprocess.run(list(argv), capture_output=True, text=True).returncode


def sh(shell, script, cwd=None, **env_extra):
    env = dict(os.environ, LC_ALL="C.UTF-8")
    env.update(env_extra)
    return subprocess.run(shell + [script], cwd=cwd, capture_output=True, text=True, env=env, timeout=60)


def fn(name):
    return f'. "{BASHD / "functions" / (name + ".sh")}"'


# ---- every file parses ---------------------------------------------------- #

@pytest.mark.parametrize("path", FUNCTIONS + ALIASES, ids=lambda p: p.parent.name + "/" + p.name)
def test_file_parses_in_bash(path):
    assert rc("bash", "-n", str(path)) == 0


@pytest.mark.parametrize("path", FUNCTIONS + ALIASES, ids=lambda p: p.parent.name + "/" + p.name)
def test_file_parses_in_zsh_unless_bash_only(path):
    ok = rc("zsh", "-n", str(path)) == 0 and rc("zsh", "--emulate", "sh", "-n", str(path)) == 0
    if path.name in BASH_ONLY:
        assert not ok, f"{path.name} now parses in zsh: take it off BASH_ONLY"
    else:
        assert ok, f"{path.name} cannot be parsed by zsh, so the loader would skip it"


def test_nano_enable_script_parses_in_zsh():
    assert rc("zsh", "-n", str(ROOT / ".config" / "nano" / "enable-x.sh")) == 0


# ---- the temperature functions give the same answers in both shells -------- #

@pytest.mark.parametrize("shell", SHELLS)
@pytest.mark.parametrize("name,arg,expect", [
    ("ctof", "100", "212.0000"), ("ctof", "-40.5", "-40.9000"), ("ftoc", "212", "100.0000"),
    ("ctok", "0", "273.15"), ("ftok", "32", "273.15"),
])
def test_temperature_conversion(shell, name, arg, expect):
    r = sh(shell, f"{fn(name)}; {name} {arg}")
    assert r.returncode == 0, r.stderr
    assert r.stdout.strip() == expect


@pytest.mark.parametrize("shell", SHELLS)
@pytest.mark.parametrize("name", ["ctof", "ftoc", "ctok", "ftok"])
@pytest.mark.parametrize("bad", ["abc", "1.2.3", "--5", ""])
def test_temperature_rejects_non_numbers(shell, name, bad):
    r = sh(shell, f"{fn(name)}; {name} '{bad}'")
    assert r.returncode != 0
    assert "not a valid number" in r.stdout or "Usage" in r.stdout or "usage" in r.stdout.lower()


# ---- help, misc, repeat ------------------------------------------------------ #

@pytest.mark.parametrize("shell", SHELLS)
def test_help_function_is_defined(shell):
    r = sh(shell, f"{fn('commands')}; type help")
    assert r.returncode == 0 and "function" in r.stdout.lower()


@pytest.mark.parametrize("shell", SHELLS)
@pytest.mark.parametrize("name", ["roll-dice", "change_hostname"])
def test_misc_functions_are_defined(shell, name):
    r = sh(shell, f"{fn('misc')}; type {name}")
    assert r.returncode == 0 and "function" in r.stdout.lower()


def test_repeat_is_no_longer_in_misc():
    r = sh(["bash", "-c"], f"{fn('misc')}; type repeat")
    assert r.returncode != 0


def test_repeat_still_works_in_bash():
    r = sh(["bash", "-c"], f"{fn('repeat')}; repeat 3 echo hi")
    assert r.returncode == 0 and r.stdout == "hi\nhi\nhi\n"
    r = sh(["bash", "-c"], f"{fn('repeat')}; repeat 0 echo hi")
    assert r.returncode == 1 and "Usage" in r.stdout


# ---- nano: the function must replace the alias without a parse error --------- #

def test_nano_function_replaces_the_alias_in_zsh(tmp_path):
    (tmp_path / ".config" / "nano").mkdir(parents=True)
    (tmp_path / ".config" / "nano" / "xnanorc").write_text("# test\n")
    script = f"""alias nano='nano --smarthome'; . "{ROOT / '.config/nano/enable-x.sh'}"; whence -w nano"""
    r = sh(["zsh", "-c"], script, HOME=str(tmp_path), TERM="xterm-256color")
    assert "parse error" not in r.stderr and "defining function based on alias" not in r.stderr, r.stderr
    assert r.stdout.strip().endswith("function"), (r.stdout, r.stderr)


def test_nano_function_is_unchanged_without_an_alias(tmp_path):
    (tmp_path / ".config" / "nano").mkdir(parents=True)
    (tmp_path / ".config" / "nano" / "xnanorc").write_text("# test\n")
    script = f""". "{ROOT / '.config/nano/enable-x.sh'}"; whence -f nano"""
    r = sh(["zsh", "-c"], script, HOME=str(tmp_path), TERM="xterm-256color")
    assert r.returncode == 0
    assert "command nano -f" in r.stdout and "xnanorc" in r.stdout
    assert "--smarthome" not in r.stdout          # we did not change what the function runs


# ---- the whole loader, in a real interactive zsh, starts clean -------------- #

@pytest.fixture
def home(tmp_path):
    (tmp_path / "work").mkdir()
    for name in (".config", ".local", ".zshrc"):
        (tmp_path / name).symlink_to(ROOT / name)
    return tmp_path


def zsh_interactive(home, script):
    env = dict(os.environ, HOME=str(home), ZDOTDIR=str(home), TERM="xterm-256color", LC_ALL="C.UTF-8", ANIM="0")
    return subprocess.run(["zsh", "-i", "-c", script], cwd=home / "work", stdin=subprocess.DEVNULL,
                          capture_output=True, text=True, env=env, timeout=120)


def test_full_zsh_startup_has_no_parse_errors_and_skips_only_bash_only_files(home):
    r = zsh_interactive(home, "true")
    assert "parse error" not in r.stderr, r.stderr
    assert "defining function based on alias" not in r.stderr, r.stderr
    skipped = [l for l in r.stderr.splitlines() if "dotfiles: skipped" in l]
    names = {pathlib.Path(l.split("skipped ")[1].split(" (")[0]).name for l in skipped}
    assert names <= BASH_ONLY, f"unexpectedly skipped: {sorted(names - BASH_ONLY)}"


def test_full_zsh_startup_loads_the_functions_and_the_animated_commands(home):
    r = zsh_interactive(home, "for c in help ctof roll-dice change_hostname mv rsync nano; do printf '%s=' $c; whence -w $c; done; ctof 100; repeat 2 echo hi")
    out = r.stdout
    for c in ("help", "ctof", "roll-dice", "change_hostname", "mv", "rsync", "nano"):
        assert f"{c}=" in out and f"{c}: function" in out, (c, out, r.stderr)
    assert "212.0000" in out
    assert out.count("hi") == 2                    # zsh's own repeat still works
