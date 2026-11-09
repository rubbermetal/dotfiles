"""Shell glue for the second batch: ln, mkdir, chown, chgrp, shred, wget, umount and the shortcuts dl, rmd, mx, um."""
import getpass
import grp
import os
import pathlib
import subprocess

import pytest

from test_anim_shell import ALIASES, BIN, SHELLS, sh, sh_pty, src

WRAPPED = ["ln", "mkdir", "chown", "chgrp", "shred", "wget", "umount"]
SHORTCUTS = ["dl", "rmd", "mx", "um"]
ALL = WRAPPED + SHORTCUTS
USER = getpass.getuser()
GROUP = grp.getgrgid(os.getgid()).gr_name


def fake(tmp_path, name):
    """A stand-in program that prints its arguments, put first on PATH."""
    bindir = tmp_path / "fakebin"
    bindir.mkdir(exist_ok=True)
    f = bindir / name
    f.write_text(f'#!/bin/sh\necho "{name.upper()}-ARGS: $@"\n')
    f.chmod(0o755)
    return str(bindir)


def path_with(bindir):
    """The fake program first, then the dotfiles' own bin (where anim lives), then the normal PATH."""
    return os.pathsep.join([bindir, str(BIN), os.environ["PATH"]])


# ---- the files ------------------------------------------------------------- #

@pytest.mark.parametrize("name", ALL)
def test_alias_file_has_usage_and_documents_anim_off(name):
    text = (ALIASES / f"{name}.sh").read_text()
    assert "# Usage:" in text and "ANIM=0" in text


@pytest.mark.parametrize("name", ALL)
def test_alias_file_parses_the_way_the_loader_checks_it(name):
    f = str(ALIASES / f"{name}.sh")
    assert subprocess.run(["bash", "-n", f]).returncode == 0
    assert subprocess.run(["zsh", "-n", f]).returncode == 0
    assert subprocess.run(["zsh", "--emulate", "sh", "-n", f]).returncode == 0


@pytest.mark.parametrize("name", ALL)
@pytest.mark.parametrize("shell", SHELLS)
def test_sourcing_defines_a_function_not_an_alias(shell, name, tmp_path):
    r = sh(shell, f"{src(name)}; type {name}", tmp_path)
    assert r.returncode == 0, r.stderr
    assert "function" in r.stdout.lower() and "is an alias" not in r.stdout.lower()


@pytest.mark.parametrize("name", ALL)
@pytest.mark.parametrize("shell", SHELLS)
def test_an_existing_alias_is_replaced_without_error(shell, name, tmp_path):
    r = sh(shell, f"alias {name}='echo OLD-ALIAS'; {src(name)}; type {name}", tmp_path)
    assert "function" in r.stdout.lower()
    assert "defining function based on alias" not in r.stderr and "parse error" not in r.stderr


@pytest.mark.parametrize("name,flags", [
    ("ln", ["-i"]), ("mkdir", ["-vp"]), ("chown", ["--preserve-root"]), ("chgrp", ["--preserve-root"]),
    ("shred", ["--force", "--remove", "--verbose"]), ("wget", ["-c"]),
])
def test_old_alias_flags_are_in_the_file(name, flags):
    text = (ALIASES / f"{name}.sh").read_text()
    for flag in flags:
        assert f"{name} {flag}" in text or f" {flag}" in text, (name, flag)


# ---- old behaviour is preserved when not on a terminal ---------------------- #

@pytest.mark.parametrize("shell", SHELLS)
def test_ln_links_and_still_asks_before_overwriting(shell, tmp_path):
    (tmp_path / "a").write_text("A")
    r = sh(shell, f"{src('ln')}; ln -s a b", tmp_path)
    assert r.returncode == 0 and (tmp_path / "b").is_symlink()
    (tmp_path / "c").write_text("C")
    sh(shell, f"{src('ln')}; ln -s a c", tmp_path, input="n\n")      # -i asks, we say no
    assert not (tmp_path / "c").is_symlink()


@pytest.mark.parametrize("shell", SHELLS)
def test_mkdir_is_verbose_and_creates_parents(shell, tmp_path):
    r = sh(shell, f"{src('mkdir')}; mkdir x/y/z", tmp_path)
    assert r.returncode == 0 and (tmp_path / "x/y/z").is_dir()
    assert "created directory" in r.stdout


@pytest.mark.parametrize("shell", SHELLS)
def test_chown_and_chgrp_work_on_your_own_files(shell, tmp_path):
    (tmp_path / "f").write_text("F")
    r = sh(shell, f"{src('chown')}; chown {USER} f", tmp_path)
    assert r.returncode == 0
    r = sh(shell, f"{src('chgrp')}; chgrp {GROUP} f", tmp_path)
    assert r.returncode == 0


@pytest.mark.parametrize("shell", SHELLS)
def test_shred_is_verbose_and_removes_the_file(shell, tmp_path):
    (tmp_path / "f").write_text("secret")
    r = sh(shell, f"{src('shred')}; shred f", tmp_path)
    assert r.returncode == 0 and not (tmp_path / "f").exists()
    assert "removed" in (r.stdout + r.stderr)


@pytest.mark.parametrize("shell", SHELLS)
def test_wget_adds_the_resume_flag(shell, tmp_path):
    r = sh(shell, f"{src('wget')}; wget http://x.test/f", tmp_path, PATH=path_with(fake(tmp_path, "wget")))
    assert "WGET-ARGS: -c http://x.test/f" in r.stdout


@pytest.mark.parametrize("shell", SHELLS)
def test_umount_passes_its_arguments(shell, tmp_path):
    r = sh(shell, f"{src('umount')}; umount /mnt/x", tmp_path, PATH=path_with(fake(tmp_path, "umount")))
    assert "UMOUNT-ARGS: /mnt/x" in r.stdout


# ---- shortcuts keep their old chaining -------------------------------------- #

@pytest.mark.parametrize("shell", SHELLS)
def test_dl_goes_through_wget_with_the_download_directory_and_resume(shell, tmp_path):
    bindir = fake(tmp_path, "wget")
    r = sh(shell, f"{src('wget')}; {src('dl')}; dl http://x.test/f", tmp_path, PATH=path_with(bindir), HOME=str(tmp_path))
    assert f"WGET-ARGS: -c -P {tmp_path}/Downloads http://x.test/f" in r.stdout


@pytest.mark.parametrize("shell", SHELLS)
def test_um_goes_through_umount(shell, tmp_path):
    r = sh(shell, f"{src('umount')}; {src('um')}; um /mnt/x", tmp_path, PATH=path_with(fake(tmp_path, "umount")))
    assert "UMOUNT-ARGS: /mnt/x" in r.stdout


@pytest.mark.parametrize("shell", SHELLS)
def test_mx_makes_a_file_executable_verbosely(shell, tmp_path):
    f = tmp_path / "run.sh"
    f.write_text("#!/bin/sh\n")
    f.chmod(0o644)
    r = sh(shell, f"{src('chmod')}; {src('mx')}; mx run.sh", tmp_path)
    assert r.returncode == 0 and "changed from" in r.stdout
    assert f.stat().st_mode & 0o111 == 0o111


@pytest.mark.parametrize("shell", SHELLS)
def test_rmd_removes_a_directory_without_asking_as_it_always_did(shell, tmp_path):
    # rm -I is overridden by the --force that rmd passes last, so rmd never prompts (the old alias behaved the same)
    d = tmp_path / "old"
    d.mkdir()
    (d / "f").write_text("x")
    r = sh(shell, f"{src('rm')}; {src('rmd')}; rmd old", tmp_path, input="n\n")
    assert r.returncode == 0 and not d.exists()
    assert "removed" in r.stdout


@pytest.mark.parametrize("name", ["ln", "mkdir", "chown", "chgrp", "shred", "wget", "umount"])
@pytest.mark.parametrize("shell", SHELLS)
def test_exit_status_is_preserved(shell, name, tmp_path):
    cmd = {"ln": "ln nope1 nope2/nope3", "mkdir": "mkdir /proc/nope/x", "chown": f"chown {USER} nope1",
           "chgrp": f"chgrp {GROUP} nope1", "shred": "shred nope1", "wget": "wget --bogus-flag-xyz",
           "umount": "umount /definitely/not/mounted-xyz"}[name]
    r = sh(shell, f"{src(name)}; {cmd}", tmp_path)
    ref = subprocess.run(["sh", "-c", cmd], cwd=tmp_path, capture_output=True, text=True)
    assert r.returncode != 0 and ref.returncode != 0, (name, r.returncode, ref.returncode)


# ---- on a terminal they use anim ----------------------------------------------- #

def test_real_commands_are_animated_on_a_terminal(tmp_path):
    shell = ["bash", "-c"]
    (tmp_path / "a").write_text("A")
    for script in (f"{src('ln')}; ln -s a link1", f"{src('mkdir')}; mkdir newdir",
                   f"{src('chown')}; chown {USER} a", f"{src('chgrp')}; chgrp {GROUP} a",
                   f"{src('shred')}; shred a"):
        code, out = sh_pty(shell, script, tmp_path)
        assert code == 0, (script, out)
        assert "" in out, (script, out)


@pytest.mark.parametrize("name,call", [("wget", "wget http://x.test/f.tgz"), ("umount", "umount /mnt/x")])
def test_fake_wget_and_umount_are_animated_on_a_terminal(tmp_path, name, call):
    code, out = sh_pty(["bash", "-c"], f"{src(name)}; {call}", tmp_path, PATH=path_with(fake(tmp_path, name)))
    assert code == 0
    assert f"{name.upper()}-ARGS" in out and "" in out


def test_dl_is_animated_through_wget_on_a_terminal(tmp_path):
    bindir = fake(tmp_path, "wget")
    code, out = sh_pty(["bash", "-c"], f"{src('wget')}; {src('dl')}; dl http://x.test/f.tgz", tmp_path,
                       PATH=path_with(bindir), HOME=str(tmp_path))
    assert code == 0 and "" in out and "Downloads" in out


@pytest.mark.parametrize("shell", SHELLS)
def test_anim_zero_turns_the_new_ones_off_on_a_terminal(shell, tmp_path):
    code, out = sh_pty(shell, f"{src('mkdir')}; mkdir newdir", tmp_path, ANIM="0")
    assert code == 0 and (tmp_path / "newdir").is_dir()
    assert "" not in out and "[ok]" not in out
    assert "created directory" in out
