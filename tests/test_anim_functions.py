"""Shell glue for the function animations: functions/{trash,extract,mkcd,...}.sh in bash and in zsh (sh emulation).

Each function does its real work first, then plays one result line. These also pin the zsh fixes.
"""
import pathlib
import stat
import subprocess

import pytest

from test_anim_shell import BIN, ROOT, SHELLS, sh, sh_pty

FUNCS = ROOT / ".config" / "bash.d" / "functions"
NAMES = ["trash", "trashempty", "extract", "mkcd", "mvg", "cpg", "chmodfix", "chmodcopy", "chmoddirs", "chmodfiles"]
OK = "[ok]"
FAIL = "[x]"


def load(*names):
    """Source the helper, ask, then the named function files, in the loader's order."""
    files = ["_anim_result", "ask", "chmoddirs"] + list(names)
    return "; ".join(f'. "{FUNCS / (f + ".sh")}"' for f in dict.fromkeys(files))


def home(tmp_path):
    h = tmp_path / "home"
    (h / ".local/share/Trash/files").mkdir(parents=True)
    return h


def run(shell, name, script, tmp_path, **extra):
    return sh(shell, f"{load(name)}; {script}", tmp_path, HOME=str(home(tmp_path)), **extra)


def tty(shell, name, script, tmp_path, **extra):
    extra.setdefault("ANIM_ASCII", "1")
    return sh_pty(shell, f"{load(name)}; {script}", tmp_path, HOME=str(home(tmp_path)), **extra)


# ---- the files ------------------------------------------------------------- #

@pytest.mark.parametrize("name", NAMES + ["_anim_result"])
def test_file_parses_the_way_the_loader_checks_it(name):
    f = str(FUNCS / f"{name}.sh")
    assert subprocess.run(["bash", "-n", f]).returncode == 0
    assert subprocess.run(["zsh", "-n", f]).returncode == 0
    assert subprocess.run(["zsh", "--emulate", "sh", "-n", f]).returncode == 0


@pytest.mark.parametrize("name", NAMES)
def test_file_documents_how_to_turn_it_off(name):
    assert "ANIM=0" in (FUNCS / f"{name}.sh").read_text()


# ---- the result line ------------------------------------------------------- #

@pytest.mark.parametrize("shell", SHELLS)
def test_plays_on_a_terminal(shell, tmp_path):
    code, out = tty(shell, "mkcd", "mkcd new/dir", tmp_path)
    assert code == 0 and OK in out and "new/dir" in out


@pytest.mark.parametrize("shell", SHELLS)
def test_not_on_a_pipe(shell, tmp_path):
    r = run(shell, "mkcd", "mkcd new/dir", tmp_path)
    assert OK not in r.stdout and r.returncode == 0


@pytest.mark.parametrize("shell", SHELLS)
def test_anim_0_turns_it_off(shell, tmp_path):
    code, out = tty(shell, "mkcd", "mkcd new/dir", tmp_path, ANIM="0")
    assert code == 0 and OK not in out


@pytest.mark.parametrize("shell", SHELLS)
def test_only_one_result_line_not_one_per_inner_command(shell, tmp_path):
    aliases = ROOT / ".config" / "bash.d" / "aliases"
    script = f'. "{aliases / "mkdir.sh"}"; mkcd new/dir'
    code, out = tty(shell, "mkcd", script, tmp_path)
    assert out.count(OK) == 1


@pytest.mark.parametrize("shell", SHELLS)
def test_anim_setting_is_restored_afterwards(shell, tmp_path):
    r = run(shell, "mkcd", 'ANIM=7; mkcd new/dir; echo "ANIM=$ANIM"', tmp_path)
    assert "ANIM=7" in r.stdout


@pytest.mark.parametrize("shell", SHELLS)
def test_failure_keeps_status_and_shows_failure(shell, tmp_path):
    code, out = tty(shell, "extract", "extract missing.tgz; echo rc=$?", tmp_path)
    assert "rc=1" in out and FAIL in out


@pytest.mark.parametrize("shell", SHELLS)
def test_no_arguments_prints_usage_and_no_line(shell, tmp_path):
    code, out = tty(shell, "extract", "extract; echo rc=$?", tmp_path)
    assert "Usage" in out and "rc=1" in out and OK not in out and FAIL not in out


@pytest.mark.parametrize("shell", SHELLS)
def test_works_when_anim_is_not_installed(shell, tmp_path):
    code, out = tty(shell, "mkcd", "command() { return 1; }; mkcd new/dir; echo rc=$?", tmp_path)
    assert "rc=0" in out and OK not in out


# ---- each function still does its job, with the result line ---------------- #

@pytest.mark.parametrize("shell", SHELLS)
def test_mkcd_changes_directory_in_this_shell(shell, tmp_path):
    r = run(shell, "mkcd", "mkcd d/e; pwd", tmp_path)
    assert r.stdout.strip().endswith("/d/e")


@pytest.mark.parametrize("shell", SHELLS)
def test_mvg_moves_and_enters_a_directory(shell, tmp_path):
    (tmp_path / "f").write_text("x")
    (tmp_path / "m").mkdir()
    r = run(shell, "mvg", "mvg f m; pwd", tmp_path)
    assert (tmp_path / "m/f").exists() and r.stdout.strip().endswith("/m")


@pytest.mark.parametrize("shell", SHELLS)
def test_mvg_rename_is_a_success(shell, tmp_path):
    (tmp_path / "f").write_text("x")
    code, out = tty(shell, "mvg", "mvg f g; echo rc=$?", tmp_path)
    assert (tmp_path / "g").exists() and "rc=0" in out and OK in out and FAIL not in out


@pytest.mark.parametrize("shell", SHELLS)
def test_cpg_copies_to_the_named_destination(shell, tmp_path):
    (tmp_path / "c1").write_text("x")
    r = run(shell, "cpg", "cpg c1 c3; echo rc=$?", tmp_path)
    assert (tmp_path / "c3").exists() and not (tmp_path / "0").exists() and "rc=0" in r.stdout


@pytest.mark.parametrize("shell", SHELLS)
def test_cpg_many_files_into_a_directory_and_enters_it(shell, tmp_path):
    (tmp_path / "c1").write_text("x")
    (tmp_path / "c2").write_text("x")
    (tmp_path / "n").mkdir()
    r = run(shell, "cpg", "cpg c1 c2 n; pwd", tmp_path)
    assert (tmp_path / "n/c1").exists() and (tmp_path / "n/c2").exists() and r.stdout.strip().endswith("/n")


@pytest.mark.parametrize("shell", SHELLS)
@pytest.mark.parametrize("answer,want", [("y", "new"), ("n", "old")])
def test_cpg_overwrite_prompt_is_honored(shell, tmp_path, answer, want):
    (tmp_path / "a").write_text("new")
    (tmp_path / "b").write_text("old")
    sh(shell, f"{load('cpg')}; cpg a b", tmp_path, input=answer + "\n", HOME=str(home(tmp_path)))
    assert (tmp_path / "b").read_text() == want


@pytest.mark.parametrize("shell", SHELLS)
def test_trash_moves_to_the_trash(shell, tmp_path):
    (tmp_path / "f").write_text("x")
    r = run(shell, "trash", "trash f", tmp_path)
    assert r.returncode == 0 and (tmp_path / "home/.local/share/Trash/files/f").exists() and not (tmp_path / "f").exists()


@pytest.mark.parametrize("shell", SHELLS)
def test_trashempty_empties_everything_including_dotfiles(shell, tmp_path):
    h = home(tmp_path)
    files = h / ".local/share/Trash/files"
    (files / "a").write_text("x")
    (files / ".hidden").write_text("x")
    (files / "d").mkdir()
    (files / "d/inner").write_text("x")
    keep = h / "keep"
    keep.write_text("x")
    r = sh(shell, f"{load('trashempty')}; trashempty; echo rc=$?", tmp_path, HOME=str(h))
    assert "rc=0" in r.stdout and list(files.iterdir()) == [] and files.exists() and keep.exists()


@pytest.mark.parametrize("shell", SHELLS)
def test_extract_unpacks(shell, tmp_path):
    (tmp_path / "src").mkdir()
    (tmp_path / "src/z").write_text("x")
    subprocess.run(["tar", "czf", "ar.tgz", "src"], cwd=tmp_path, check=True)
    r = run(shell, "extract", "extract ar.tgz out", tmp_path)
    assert r.returncode == 0 and (tmp_path / "out/src/z").exists()


def mode(p):
    return stat.S_IMODE(p.stat().st_mode)


@pytest.mark.parametrize("shell", SHELLS)
def test_chmodcopy(shell, tmp_path):
    (tmp_path / "r").write_text("x")
    (tmp_path / "s").write_text("x")
    (tmp_path / "r").chmod(0o640)
    code, out = tty(shell, "chmodcopy", "chmodcopy r s", tmp_path)
    assert code == 0 and mode(tmp_path / "s") == 0o640 and OK in out


def tree(tmp_path):
    (tmp_path / "p/q").mkdir(parents=True)
    (tmp_path / "p/q/f").write_text("x")
    (tmp_path / "p/q/f").chmod(0o600)
    (tmp_path / "p/q").chmod(0o755)


@pytest.mark.parametrize("shell", SHELLS)
def test_chmoddirs_yes_answer_applies(shell, tmp_path):
    tree(tmp_path)
    sh(shell, f"{load('chmoddirs')}; chmoddirs 700 p", tmp_path, input="y\n", HOME=str(home(tmp_path)))
    assert mode(tmp_path / "p/q") == 0o700


@pytest.mark.parametrize("shell", SHELLS)
def test_chmoddirs_no_answer_changes_nothing(shell, tmp_path):
    tree(tmp_path)
    sh(shell, f"{load('chmoddirs')}; chmoddirs 700 p", tmp_path, input="n\n", HOME=str(home(tmp_path)))
    assert mode(tmp_path / "p/q") == 0o755


@pytest.mark.parametrize("shell", SHELLS)
def test_chmodfiles_yes_answer_applies(shell, tmp_path):
    tree(tmp_path)
    sh(shell, f"{load('chmodfiles')}; chmodfiles 644 p", tmp_path, input="y\n", HOME=str(home(tmp_path)))
    assert mode(tmp_path / "p/q/f") == 0o644


@pytest.mark.parametrize("shell", SHELLS)
def test_chmodfiles_no_answer_changes_nothing(shell, tmp_path):
    tree(tmp_path)
    sh(shell, f"{load('chmodfiles')}; chmodfiles 644 p", tmp_path, input="n\n", HOME=str(home(tmp_path)))
    assert mode(tmp_path / "p/q/f") == 0o600


@pytest.mark.parametrize("shell", SHELLS)
def test_yes_flag_shows_the_line(shell, tmp_path):
    tree(tmp_path)
    code, out = tty(shell, "chmoddirs", "chmoddirs -y 700 p", tmp_path)
    assert code == 0 and OK in out and "700" in out


# A declined prompt changed nothing, so it must not end with a check mark.
@pytest.mark.parametrize("shell", SHELLS)
@pytest.mark.parametrize("name,cmd", [("chmoddirs", "chmoddirs 700 p"), ("chmodfiles", "chmodfiles 644 p")])
def test_declined_prompt_shows_no_result_line(shell, tmp_path, name, cmd):
    tree(tmp_path)
    code, out = tty(shell, name, f"{cmd} < /dev/null", tmp_path)
    assert OK not in out and FAIL not in out


@pytest.mark.parametrize("shell", SHELLS)
def test_a_decline_does_not_hide_the_next_result_line(shell, tmp_path):
    tree(tmp_path)
    code, out = tty(shell, "chmoddirs", "chmoddirs 700 p < /dev/null; chmoddirs -y 700 p", tmp_path)
    assert out.count(OK) == 1


# ---- anim --result --------------------------------------------------------- #

def anim(*args, **kw):
    return subprocess.run([str(BIN / "anim"), *args], capture_output=True, text=True, **kw)


def test_result_returns_the_given_status_and_prints_nothing_on_a_pipe():
    r = anim("--result", "mkcd", "3", "d")
    assert r.returncode == 3 and r.stdout == ""


def test_result_never_runs_the_name_as_a_command(tmp_path):
    marker = tmp_path / "ran"
    r = anim("--result", "touch", "0", str(marker))
    assert r.returncode == 0 and not marker.exists()


def test_result_bad_status_is_a_usage_error():
    assert anim("--result", "mkcd", "abc", "d").returncode == 2
    assert anim("--result").returncode == 2
    assert anim("--result", "mkcd").returncode == 2
