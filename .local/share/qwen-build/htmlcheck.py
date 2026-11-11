"""
Cheap structure facts about an HTML (or Jinja-HTML) text, for before/after comparison.

Usage example:
    if tag_balance(new_text) != tag_balance(old_text): ...   # a tag was dropped or added unpaired
    for script in inline_scripts(text): ...                  # bodies of <script> blocks without src
    for sheet in inline_styles(text): ...                    # bodies of <style> blocks

Neither function validates HTML; they only report what html.parser sees, so the same
oddities (Jinja tags, sloppy markup) give the same answer before and after an edit.
"""

from html.parser import HTMLParser

VOID = {"area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param",
        "source", "track", "wbr"}


class _Scan(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.balance = {}
        self.scripts = []
        self.styles = []
        self._in_script = False
        self._in_style = False

    def handle_starttag(self, tag, attrs):
        if tag in VOID:
            return
        self.balance[tag] = self.balance.get(tag, 0) + 1
        if tag == "script":
            self._in_script = not any(name == "src" for name, _ in attrs)
            if self._in_script:
                self.scripts.append("")
        if tag == "style":
            self._in_style = True
            self.styles.append("")

    def handle_startendtag(self, tag, attrs):
        pass                                    # <x/> opens and closes itself

    def handle_endtag(self, tag):
        if tag in VOID:
            return
        self.balance[tag] = self.balance.get(tag, 0) - 1
        if tag == "script":
            self._in_script = False
        if tag == "style":
            self._in_style = False

    def handle_data(self, data):
        if self._in_script:
            self.scripts[-1] += data
        if self._in_style:
            self.styles[-1] += data


def _scan(text):
    scan = _Scan()
    scan.feed(text)
    scan.close()
    return scan


def tag_balance(text):
    """{tag: opening tags minus closing tags}, only tags where that is not zero."""
    return {tag: n for tag, n in _scan(text).balance.items() if n != 0}


def inline_scripts(text):
    """Bodies of the <script> elements that have no src attribute, in document order."""
    return _scan(text).scripts


def inline_styles(text):
    """Bodies of the <style> elements, in document order."""
    return _scan(text).styles
