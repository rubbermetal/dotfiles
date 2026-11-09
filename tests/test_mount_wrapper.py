"""mount: bare `mount` lists in columns; with arguments it must really mount."""
import pytest

from test_anim_shell import SHELLS, sh, src
from test_anim_shell_more import fake, path_with


@pytest.mark.parametrize("shell", SHELLS)
def test_arguments_reach_mount(shell, tmp_path):
    r = sh(shell, f"{src('mount')}; mount /dev/sdb1 /mnt", tmp_path, PATH=path_with(fake(tmp_path, "mount")))
    assert "MOUNT-ARGS: /dev/sdb1 /mnt" in r.stdout


@pytest.mark.parametrize("shell", SHELLS)
def test_options_reach_mount(shell, tmp_path):
    r = sh(shell, f"{src('mount')}; mount -o ro -t ext4 /dev/sdb1 /mnt", tmp_path, PATH=path_with(fake(tmp_path, "mount")))
    assert "MOUNT-ARGS: -o ro -t ext4 /dev/sdb1 /mnt" in r.stdout


@pytest.mark.parametrize("shell", SHELLS)
def test_bare_mount_is_aligned_in_columns(shell, tmp_path):
    bindir = tmp_path / "fakebin"
    bindir.mkdir()
    m = bindir / "mount"
    m.write_text("#!/bin/sh\necho 'a b'\necho 'longer c'\n")
    m.chmod(0o755)
    r = sh(shell, f"{src('mount')}; mount", tmp_path, PATH=path_with(str(bindir)))
    assert r.stdout.splitlines() == ["a       b", "longer  c"]
