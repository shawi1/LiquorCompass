#!/usr/bin/env python3
"""Generate icon.svg for LiquorCompass.

Run from the design/ directory; outputs icon.svg next to this script.
Convert to PNG with:
    rsvg-convert -w 1024 -h 1024 icon.svg -o icon.png
"""
import math
from pathlib import Path

SIZE = 1024
C = SIZE / 2  # center

def ticks() -> str:
    parts = []
    # 72 ticks every 5 degrees; major every 30 degrees (i % 6 == 0)
    for i in range(72):
        angle = i * 5
        major = (i % 6 == 0)
        length = 28 if major else 14
        width = 5 if major else 2.5
        opacity = 0.85 if major else 0.35
        # tick centered at radius r, pointing inward
        outer_r = 470
        inner_r = outer_r - length
        rad = math.radians(angle - 90)  # 0 at top
        x1 = C + math.cos(rad) * outer_r
        y1 = C + math.sin(rad) * outer_r
        x2 = C + math.cos(rad) * inner_r
        y2 = C + math.sin(rad) * inner_r
        parts.append(
            f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" '
            f'stroke="#F2C770" stroke-width="{width}" stroke-linecap="round" opacity="{opacity}"/>'
        )
    return "\n    ".join(parts)


SVG = f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {SIZE} {SIZE}" width="{SIZE}" height="{SIZE}">
  <defs>
    <radialGradient id="bg" cx="50%" cy="38%" r="72%">
      <stop offset="0%" stop-color="#F0A546"/>
      <stop offset="40%" stop-color="#A85A1A"/>
      <stop offset="80%" stop-color="#3A1C08"/>
      <stop offset="100%" stop-color="#150801"/>
    </radialGradient>

    <radialGradient id="vignette" cx="50%" cy="50%" r="65%">
      <stop offset="60%" stop-color="#000000" stop-opacity="0"/>
      <stop offset="100%" stop-color="#000000" stop-opacity="0.55"/>
    </radialGradient>

    <linearGradient id="glassFill" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#FFFFFF" stop-opacity="0.97"/>
      <stop offset="100%" stop-color="#F5E8C8" stop-opacity="0.85"/>
    </linearGradient>

    <linearGradient id="liquid" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#FF7A45"/>
      <stop offset="100%" stop-color="#C03A1A"/>
    </linearGradient>

    <radialGradient id="olive" cx="40%" cy="35%" r="60%">
      <stop offset="0%" stop-color="#FF6B5C"/>
      <stop offset="100%" stop-color="#9F1F12"/>
    </radialGradient>

    <filter id="softShadow" x="-30%" y="-30%" width="160%" height="160%">
      <feGaussianBlur in="SourceAlpha" stdDeviation="12"/>
      <feOffset dx="0" dy="6" result="offset"/>
      <feComponentTransfer><feFuncA type="linear" slope="0.55"/></feComponentTransfer>
      <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
  </defs>

  <!-- Background -->
  <rect width="{SIZE}" height="{SIZE}" fill="url(#bg)"/>
  <rect width="{SIZE}" height="{SIZE}" fill="url(#vignette)"/>

  <!-- Subtle outer ring -->
  <circle cx="{C}" cy="{C}" r="478" fill="none" stroke="#F2C770" stroke-width="2" opacity="0.18"/>
  <circle cx="{C}" cy="{C}" r="430" fill="none" stroke="#F2C770" stroke-width="1" opacity="0.10"/>

  <!-- Tick marks -->
  <g>
    {ticks()}
  </g>

  <!-- Cardinal letters -->
  <g font-family="-apple-system, 'SF Pro Rounded', 'Helvetica Neue', Helvetica, Arial, sans-serif"
     font-weight="700" text-anchor="middle">
    <text x="{C}" y="178" font-size="78" fill="#FF8A4C">N</text>
    <text x="888" y="540" font-size="56" fill="#F2C770" opacity="0.7">E</text>
    <text x="{C}" y="912" font-size="56" fill="#F2C770" opacity="0.7">S</text>
    <text x="136" y="540" font-size="56" fill="#F2C770" opacity="0.7">W</text>
  </g>

  <!-- Martini glass (acts as the compass needle, pointing N) -->
  <g transform="translate({C},{C})" filter="url(#softShadow)">
    <!-- Cone (the glass bowl), apex at bottom center -->
    <path d="M -210,-200 L 210,-200 L 0,40 Z"
          fill="url(#glassFill)" stroke="#FFFFFF" stroke-width="2" stroke-opacity="0.4"/>

    <!-- Liquid (smaller triangle inside the cone) -->
    <path d="M -174,-170 L 174,-170 L 0,15 Z" fill="url(#liquid)" opacity="0.92"/>

    <!-- Rim highlight on the glass top -->
    <path d="M -210,-200 L 210,-200" stroke="#FFFFFF" stroke-width="6" stroke-opacity="0.55" stroke-linecap="round"/>

    <!-- Stem -->
    <rect x="-7" y="40" width="14" height="170" rx="3" fill="url(#glassFill)"/>

    <!-- Base -->
    <ellipse cx="0" cy="218" rx="95" ry="14" fill="url(#glassFill)"/>

    <!-- Olive on a pick -->
    <line x1="-80" y1="-220" x2="55" y2="-95" stroke="#F2C770" stroke-width="4" stroke-linecap="round" opacity="0.9"/>
    <circle cx="55" cy="-95" r="28" fill="url(#olive)" stroke="#7A1A0E" stroke-width="2" stroke-opacity="0.6"/>
    <circle cx="48" cy="-103" r="6" fill="#FFFFFF" opacity="0.6"/>
  </g>
</svg>
"""

if __name__ == "__main__":
    out = Path(__file__).parent / "icon.svg"
    out.write_text(SVG)
    print(f"Wrote {out}")
