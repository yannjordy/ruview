import json
from pathlib import Path
from typing import Optional

class I18n:
    def __init__(self, lang: str = "en", lang_dir: Optional[Path] = None):
        self.lang_dir = lang_dir or Path(__file__).parent.parent.parent / "lang"
        self.lang = lang
        self._strings = {}
        self._fallback = {}
        self._load()

    def _load(self):
        for f in self.lang_dir.glob("*.json"):
            code = f.stem
            with open(f, encoding="utf-8") as fh:
                data = json.load(fh)
            if code == self.lang:
                self._strings = data
            if code == "en":
                self._fallback = data

    def get(self, key: str, **kwargs) -> str:
        parts = key.split(".")
        val = self._strings
        for p in parts:
            if isinstance(val, dict):
                val = val.get(p)
            else:
                val = None
                break
        if val is None:
            val = self._fallback
            for p in parts:
                if isinstance(val, dict):
                    val = val.get(p)
                else:
                    val = key
                    break
        if val is None:
            return key
        import re
        def replace(m):
            k = m.group(1)
            return str(kwargs.get(k, "{" + k + "}"))
        return re.sub(r"\{\{(\w+)\}\}", replace, str(val))

    def set_lang(self, lang: str):
        self.lang = lang
        self._load()

    @property
    def available_langs(self) -> list:
        return sorted(f.stem for f in self.lang_dir.glob("*.json"))

i18n = I18n()

def t(key: str, **kwargs) -> str:
    return i18n.get(key, **kwargs)
