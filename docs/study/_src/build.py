#!/usr/bin/env python3
"""Generate the bilingual static HTML study site from markdown sources.

Sources live next to this script as `<slug>.en.md` and `<slug>.it.md`.
Output goes to the parent directory, mirroring the `nav` structure below.

Usage:  python3 docs/study/_src/build.py
Deps:   markdown (pip install markdown)  -- nothing else, no network, no CDN.
"""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path

try:
    import markdown
except ImportError:
    sys.exit("needs `markdown`: python3 -m pip install --user markdown")

SRC = Path(__file__).resolve().parent
OUT = SRC.parent

# slug -> (output path, EN title, IT title)
# Order defines prev/next and the sidebar.
NAV: list[tuple[str, str, str, str]] = [
    ("index", "index.html", "Curriculum", "Programma"),
    ("00-version-map", "00-version-map.html", "Version Map", "Mappa delle versioni"),
    ("00-baseline", "00-baseline.html", "Baseline", "Punto di partenza"),
    ("wwdc22-index", "wwdc22/index.html", "WWDC22 — Overview", "WWDC22 — Panoramica"),
    ("wwdc22-01", "wwdc22/01-generics-and-existentials.html",
     "1 · Generics & Existentials", "1 · Generics ed existentials"),
    ("wwdc22-02", "wwdc22/02-regex-and-string-processing.html",
     "2 · Regex & String Processing", "2 · Regex ed elaborazione di stringhe"),
    ("wwdc22-03", "wwdc22/03-concurrency-foundations.html",
     "3 · Concurrency Foundations", "3 · Fondamenta di concorrenza"),
    ("wwdc22-04", "wwdc22/04-swiftui-navigation-and-layout.html",
     "4 · SwiftUI Navigation & Layout", "4 · Navigazione e layout in SwiftUI"),
    ("wwdc22-05", "wwdc22/05-platform-debuts.html",
     "5 · Platform Debuts", "5 · Debutti di piattaforma"),
    ("wwdc22-06", "wwdc22/06-build-challenges.html",
     "6 · Build Challenges", "6 · Sfide di implementazione"),
    ("review-protocol", "review-protocol.html",
     "Review Protocol", "Protocollo di revisione"),
]

GROUPS = [
    (None, ["index", "00-version-map", "00-baseline", "review-protocol"]),
    (("WWDC22 · Swift 5.7 · iOS 16", "WWDC22 · Swift 5.7 · iOS 16"),
     ["wwdc22-index", "wwdc22-01", "wwdc22-02", "wwdc22-03",
      "wwdc22-04", "wwdc22-05", "wwdc22-06"]),
]

UI = {
    "en": {
        "site": "Swift Study",
        "sub": "WWDC22 → WWDC25",
        "contents": "Contents",
        "prev": "Previous",
        "next": "Next",
        "toc": "On this page",
        "theme": "Toggle theme",
        "menu": "Menu",
        "skip": "Skip to content",
    },
    "it": {
        "site": "Studio Swift",
        "sub": "WWDC22 → WWDC25",
        "contents": "Indice",
        "prev": "Precedente",
        "next": "Successivo",
        "toc": "In questa pagina",
        "theme": "Cambia tema",
        "menu": "Menu",
        "skip": "Vai al contenuto",
    },
}

MD_EXT = ["fenced_code", "tables", "toc", "attr_list", "md_in_html", "sane_lists"]


def md_to_html(text: str) -> str:
    return markdown.Markdown(extensions=MD_EXT, output_format="html5").convert(text)


def rewrite_links(html: str, from_path: str) -> str:
    """Point inter-document .md links at their generated .html counterparts."""
    by_stem = {}
    for slug, path, _, _ in NAV:
        by_stem[Path(path).name.replace(".html", "")] = path
        by_stem[slug] = path

    def repl(m: re.Match) -> str:
        href = m.group(1)
        if "://" in href or href.startswith("#"):
            return m.group(0)
        anchor = ""
        if "#" in href:
            href, anchor = href.split("#", 1)
            anchor = "#" + anchor
        stem = Path(href).name.replace(".md", "")
        if stem == "README":
            parent = Path(href).parent.name
            stem = f"{parent}-index" if parent else "index"
        target = by_stem.get(stem)
        if not target:
            return m.group(0)
        rel_href = os.path.relpath(target, Path(from_path).parent)
        return f'href="{rel_href}{anchor}"'

    return re.sub(r'href="([^"]+\.md(?:#[^"]*)?)"', repl, html)


def rel(from_path: str, to_path: str) -> str:
    depth = len(Path(from_path).parent.parts)
    return "../" * depth + to_path


def sidebar(current: str, lang: str) -> str:
    cur_path = dict((s, p) for s, p, _, _ in NAV)[current]
    titles = {s: (en, it) for s, _, en, it in NAV}
    paths = dict((s, p) for s, p, _, _ in NAV)
    out = []
    for header, slugs in GROUPS:
        if header:
            out.append(f'<p class="nav-group">{header[0 if lang == "en" else 1]}</p>')
        out.append("<ul>")
        for slug in slugs:
            title = titles[slug][0 if lang == "en" else 1]
            cls = ' class="active"' if slug == current else ""
            href = rel(cur_path, paths[slug])
            out.append(f'<li{cls}><a href="{href}">{title}</a></li>')
        out.append("</ul>")
    return "\n".join(out)


def page(current: str, bodies: dict[str, str], toc: dict[str, str]) -> str:
    idx = [s for s, _, _, _ in NAV].index(current)
    cur_path = dict((s, p) for s, p, _, _ in NAV)[current]
    titles = {s: (en, it) for s, _, en, it in NAV}
    paths = dict((s, p) for s, p, _, _ in NAV)
    prev_slug = NAV[idx - 1][0] if idx > 0 else None
    next_slug = NAV[idx + 1][0] if idx < len(NAV) - 1 else None

    blocks = []
    for lang in ("en", "it"):
        u = UI[lang]
        pager = []
        for slug, key, cls in ((prev_slug, "prev", "prev"), (next_slug, "next", "next")):
            if not slug:
                continue
            t = titles[slug][0 if lang == "en" else 1]
            pager.append(
                f'<a class="pager-{cls}" href="{rel(cur_path, paths[slug])}">'
                f'<span>{u[key]}</span><strong>{t}</strong></a>'
            )
        blocks.append(f"""<div class="lang" data-l="{lang}">
<nav class="sidebar-nav" aria-label="{u['contents']}">
<p class="nav-title">{u['site']}<small>{u['sub']}</small></p>
{sidebar(current, lang)}
</nav>
<article class="doc">
{bodies[lang]}
<nav class="pager">{''.join(pager)}</nav>
</article>
<aside class="toc"><p>{u['toc']}</p>{toc[lang]}</aside>
</div>""")

    title_en, title_it = titles[current]
    assets = rel(cur_path, "assets")
    return f"""<!doctype html>
<html lang="en" data-lang="en" data-theme="auto">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title_en} · Swift Study</title>
<meta name="description" content="Swift &amp; Apple platform study curriculum, WWDC22 to WWDC25, applied to the Pokespeare project.">
<link rel="stylesheet" href="{assets}/style.css">
<script>/* set theme+lang before paint to avoid flash */
(function(){{try{{var t=localStorage.getItem('study-theme');if(t)document.documentElement.dataset.theme=t;
var p=new URLSearchParams(location.search).get('lang');var l=p||localStorage.getItem('study-lang');
if(l==='it'||l==='en'){{document.documentElement.dataset.lang=l;document.documentElement.lang=l;}}}}catch(e){{}}}})();</script>
</head>
<body>
<a class="skip" href="#content">Skip to content</a>
<header class="topbar">
<button class="icon-btn" id="menu-btn" aria-label="Menu" aria-expanded="false">
<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M3 6h18M3 12h18M3 18h18"/></svg></button>
<span class="brand"><span class="lang" data-l="en">Swift Study</span><span class="lang" data-l="it">Studio Swift</span></span>
<div class="spacer"></div>
<div class="lang-switch" role="group" aria-label="Language">
<button data-set-lang="en" aria-pressed="true">EN</button><button data-set-lang="it" aria-pressed="false">IT</button>
</div>
<button class="icon-btn" id="theme-btn" aria-label="Toggle theme">
<svg class="i-sun" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="4.2"/><path d="M12 2v2.4M12 19.6V22M2 12h2.4M19.6 12H22M4.9 4.9l1.7 1.7M17.4 17.4l1.7 1.7M19.1 4.9l-1.7 1.7M6.6 17.4l-1.7 1.7"/></svg>
<svg class="i-moon" viewBox="0 0 24 24" aria-hidden="true"><path d="M20 14.5A8.5 8.5 0 1 1 9.5 4a7 7 0 0 0 10.5 10.5Z"/></svg></button>
</header>
<div class="shell" id="content">
{''.join(blocks)}
</div>
<script src="{assets}/app.js"></script>
</body>
</html>
"""


def main() -> int:
    missing = []
    generated = 0
    for slug, out_path, _, _ in NAV:
        bodies, tocs = {}, {}
        gap = False
        for lang in ("en", "it"):
            src = SRC / f"{slug}.{lang}.md"
            if not src.exists():
                missing.append(src.name)
                gap = True
                continue
            m = markdown.Markdown(extensions=MD_EXT, output_format="html5")
            bodies[lang] = rewrite_links(m.convert(src.read_text(encoding="utf-8")), out_path)
            tocs[lang] = getattr(m, "toc", "")
        if gap:
            continue
        dest = OUT / out_path
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(page(slug, bodies, tocs), encoding="utf-8")
        generated += 1
        print(f"  ✓ {out_path}")

    if missing:
        print("\n  missing sources (skipped): " + ", ".join(sorted(set(missing))))
    print(f"\n{generated} page(s) written to {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
