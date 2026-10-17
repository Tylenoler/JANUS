#!/usr/bin/env python3
"""Regenerate the bundled Noto Sans SC subset for JANUS.

The application is offline and its UI text is fixed, so shipping the full
17.8 MB CJK variable font is wasteful. This script collects every character
used by the Dart sources and project Markdown (a useful superset for
user-entered names), then asks fontTools to keep only those glyphs. Variable
weight axes and font names are preserved.

Run from anywhere:

    python tool/subset_janus_font.py

Requires fontTools (`python -m pip install fonttools`). Regenerate and commit
`assets/fonts/NotoSansSC-Subset.ttf` whenever new Chinese UI text is added.
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tool" / "fonts" / "NotoSansSC-VariableFont_wght.ttf"
OUTPUT = ROOT / "assets" / "fonts" / "NotoSansSC-Subset.ttf"

# Full-width and CJK punctuation that appears in messages and tables even when
# a particular mark is not in the current source text.
EXTRA_PUNCTUATION = set(
    "，。！？：；、“”‘’（）【】《》〈〉…—·～￥％＋－×÷＝＃＠＆＊／＼｜＜＞「」『』〔〕"
)


def collect_characters() -> set[str]:
    paths = list((ROOT / "lib").rglob("*.dart"))
    for directory in (ROOT, ROOT / "docs", ROOT / "tool"):
        if directory.exists():
            paths.extend(directory.glob("*.md"))
    characters = set(chr(code) for code in range(0x20, 0x7F))
    characters.update(EXTRA_PUNCTUATION)
    for path in paths:
        try:
            characters.update(path.read_text(encoding="utf-8"))
        except (OSError, UnicodeDecodeError):
            continue
    return characters


def main() -> int:
    if not SOURCE.exists():
        print(f"Source font not found: {SOURCE}", file=sys.stderr)
        return 1

    characters = collect_characters()
    charset_file = Path(
        tempfile.NamedTemporaryFile(
            prefix="janus-fontset-", suffix=".txt", delete=False
        ).name
    )
    charset_file.write_text(
        "".join(sorted(characters, key=ord)), encoding="utf-8"
    )
    try:
        subprocess.run(
            [
                sys.executable,
                "-m",
                "fontTools.subset",
                str(SOURCE),
                f"--output-file={OUTPUT}",
                f"--text-file={charset_file}",
                "--layout-features=*",
                "--name-IDs=*",
                "--name-languages=*",
                "--recommended-glyphs",
            ],
            check=True,
        )
    finally:
        charset_file.unlink(missing_ok=True)

    font = TTFont(OUTPUT)
    cjk_count = sum(1 for char in characters if 0x4E00 <= ord(char) <= 0x9FFF)
    axes = (
        [(axis.axisTag, axis.minValue, axis.maxValue) for axis in font["fvar"].axes]
        if "fvar" in font
        else []
    )
    print(f"characters: {len(characters)} (CJK: {cjk_count})")
    print(f"glyphs: {len(font.getGlyphOrder())}; weight axes: {axes}")
    print(f"source: {SOURCE.stat().st_size:,} bytes")
    print(f"subset: {OUTPUT.stat().st_size:,} bytes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
