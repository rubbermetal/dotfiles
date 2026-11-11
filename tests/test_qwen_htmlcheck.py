"""htmlcheck.py: tag balance and inline scripts, for before/after comparison."""
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / ".local" / "share" / "qwen-build"))

from htmlcheck import inline_scripts, tag_balance  # noqa: E402


def test_balanced_document():
    assert tag_balance("<div><p>a</p><br><img src=x><input></div>") == {}


def test_missing_and_extra_closing_tags():
    assert tag_balance("<div><div><p>a</p></div>") == {"div": 1}
    assert tag_balance("<ul></ul></ul><span>") == {"ul": -1, "span": 1}


def test_self_closing_and_void_tags_do_not_count():
    assert tag_balance("<svg><path d='x'/></svg><br/><hr>") == {}


def test_tags_inside_scripts_and_comments_do_not_count():
    assert tag_balance("<script>var s = '<div>';</script><!-- <p> -->") == {}


def test_jinja_text_is_just_text():
    assert tag_balance("{% if a %}<b>{{ x }}</b>{% endif %}") == {}


def test_inline_scripts_in_order_without_src_ones():
    text = "<script src='a.js'></script><script>one();</script><p>x</p><script type='module'>\ntwo();\n</script>"
    assert inline_scripts(text) == ["one();", "\ntwo();\n"]


def test_inline_scripts_none():
    assert inline_scripts("<p>x</p>") == []


def test_script_body_is_not_unescaped():
    assert inline_scripts("<script>a = '&amp;' < b;</script>") == ["a = '&amp;' < b;"]
