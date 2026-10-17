#!/usr/bin/env python3
"""Build the rounded JANUS Windows icon from Image/JANUS_ICON.png.

The source artwork is a full black square. Windows shows it in the taskbar and
on the executable, so the square edges are masked with a rounded rectangle at
build time. Run from anywhere:

    python tool/make_app_icon.py

Requires Pillow (`python -m pip install pillow`). Commit the resulting
`windows/runner/resources/app_icon.ico`.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Image" / "JANUS_ICON.png"
OUTPUT = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"
SIZES = (16, 24, 32, 48, 64, 128, 256)
RADIUS_RATIO = 0.22
SUPERSAMPLE = 8


def rounded_icon(source: Image.Image, size: int) -> Image.Image:
    icon = source.convert("RGBA").resize((size, size), Image.LANCZOS)
    # Draw the mask at a higher resolution, then downsample it so the corners
    # stay smooth at 16-48 px instead of turning into hard stair steps.
    mask_size = size * SUPERSAMPLE
    mask = Image.new("L", (mask_size, mask_size), 0)
    draw = ImageDraw.Draw(mask)
    radius = max(1, round(mask_size * RADIUS_RATIO))
    draw.rounded_rectangle(
        (0, 0, mask_size - 1, mask_size - 1), radius=radius, fill=255
    )
    mask = mask.resize((size, size), Image.LANCZOS)
    icon.putalpha(Image.composite(icon.getchannel("A"), Image.new("L", (size, size), 0), mask))
    return icon


def main() -> int:
    if not SOURCE.exists():
        raise SystemExit(f"Source icon not found: {SOURCE}")
    source = Image.open(SOURCE)
    frames = [rounded_icon(source, size) for size in SIZES]
    frames[-1].save(
        OUTPUT,
        format="ICO",
        sizes=[(size, size) for size in SIZES],
        append_images=frames[:-1],
    )
    frames[-1].save(ROOT / "build" / "janus-icon-preview.png")
    print(f"source: {SOURCE} {source.width}x{source.height}")
    print(f"icon: {OUTPUT} ({', '.join(str(size) for size in SIZES)} px)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
