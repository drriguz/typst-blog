# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A Tufte-style static blog generator powered by **Typst**. Posts are written in Typst with the [marginalia](https://typst.app/universe/package/marginalia) package for wide margins, sidenotes, and margin figures. A Rust CLI compiles posts into PDF and HTML (SVG with selectable text) with an index page.

## Build Commands

```bash
make build              # Build the static site (builds modified Typst automatically)
make typst-modified     # Build the modified Typst binary from submodule
make serve              # Dev server on port 9527 (cargo run -- serve --port 9527)
make clean              # Remove output/
make new                # Interactive new post creation (or: cargo run -- new "Title" --tags "tag1,tag2")
make dev                # Build then serve

cargo test              # Run unit tests (metadata parsing)
```

Typst-only (without the site generator):
```bash
typst compile --root . src/posts/YYYY-MM-DD-slug/post.typ
typst watch --root . src/posts/YYYY-MM-DD-slug/post.typ
```

## Prerequisites

- **Rust** (1.70+): <https://rustup.rs/>
- **Git submodules**: `git submodule update --init --recursive`

## Project Structure

```
├── src/
│   ├── template.typ              # Shared Tufte-style Typst template
│   └── posts/
│       └── YYYY-MM-DD-slug/
│           ├── post.typ          # Post content (Typst)
│           ├── refs.bib          # Bibliography (BibTeX)
│           └── images/           # Post-local images (.webp)
├── templates/                    # Tera HTML templates
│   ├── base.html, post.html, index.html, tag.html, tags-all.html
│   └── new-post.typ              # Scaffold for `typst-blog new`
├── static/css/style.css          # Site stylesheet
├── src/                          # Rust CLI source (main.rs, build.rs, metadata.rs, template.rs, server.rs)
├── typst-src/                    # Git submodule: modified Typst source
├── output/                       # Generated static site (gitignored)
├── typst-modified                # Built from typst-src/ (gitignored)
├── Cargo.toml
├── Makefile
└── .github/workflows/build.yml   # CI/CD pipeline
```

## Architecture

### Build Pipeline

1. Scan `src/posts/*/post.typ` for metadata (title, date, tags, summary via regex)
2. Sort posts by date descending
3. Per post:
   - **PDF**: `typst-modified compile --root . --format pdf` → full Tufte layout with marginalia
   - **SVG**: `typst-modified compile --root . --format svg` → selectable text via `<text>` elements
   - **Native HTML**: `typst-modified compile --features html --format html` → semantic HTML with MathML; the `<body>` content and `<style>` blocks from `<head>` are extracted and embedded in the HTML tab of `templates/post.html`
   - **Images**: copy `images/` to `output/posts/<slug>/images/`
4. Generate `output/index.html` and `output/tags/<tag>/index.html`
5. Copy `static/` to `output/`

The HTML tab uses Typst's **target-adaptive template**: `src/template.typ` branches on `target() == "html"`. In HTML mode marginalia (place-based, paged-only) is bypassed and the template emits semantic markup — `<span class="sidenote">`, `<aside class="margin-fig">`, `<div class="wide-fig">` — positioned by `static/css/style.css` as Tufte-style margin notes. CSS counters number the notes. The paged output is byte-identical in text content to the non-branched template.

### Modified Typst Binary

The `typst-modified` binary is built from the `typst-src/` submodule (a fork of Typst 0.15-dev). It renders text as SVG `<text>` elements instead of `<use>` elements, making text selectable and searchable in browsers.

Key changes in Typst source (`crates/typst-svg/src/text.rs`):
- `render_text()` checks if all glyphs are outline glyphs
- If so, calls `render_text_as_svg_text()` which emits `<text>` with `<tspan>` children
- Falls back to `<use>` elements for color/image glyphs

**Math font constraint:** Fonts with a MATH table (e.g., "New Computer Modern Math") must always be rendered as shapes (`<use>` with `<path>` elements), never as `<text>` elements. Browsers typically don't have math fonts installed, so `<text>` with a math `font-family` won't render correctly. The `render_text()` method checks `FontFlags::MATH` and forces the glyph path for math fonts.

The fork already includes Typst's experimental **HTML export** (semantic HTML + MathML, behind `--features html`), so no additional fork changes are needed for the HTML tab. The binary is used for all three formats (PDF, SVG, native HTML); a system `typst` on PATH is only a fallback when `typst-modified` is absent.

Limitations of the native HTML export: Typst-drawn figures (`grid`/`rect` diagrams) are ignored with a warning and render empty in the HTML tab (they remain fine in SVG/PDF); local images are inlined as base64 data URIs.

Build: `make typst-modified` (compiles from `typst-src/` submodule)

### Fonts

Installed via `apt-get` (CI) or `make fonts` (local dev):

| Role        | Font                      | apt package            |
|-------------|---------------------------|------------------------|
| Main serif  | Linux Libertine O         | `fonts-linuxlibertine` |
| CJK serif   | Noto Serif CJK SC         | `fonts-noto-cjk`       |
| Sans        | CMU Sans Serif            | `fonts-cmu`            |
| CJK sans    | Noto Sans CJK SC          | `fonts-noto-cjk`       |
| Mono        | Cascadia Code             | `fonts-cascadia-code`  |
| Math        | CMU Math                  | `fonts-cmu`            |

CSS fallbacks for HTML (fonts not served as web fonts):
- Serif: `Georgia, serif`
- Sans: `Arial, Helvetica, sans-serif`
- Mono: `Consolas, monospace`

Exception: **New Computer Modern Math** (`static/fonts/NewCMMath-Regular.woff2`, converted from the typst-assets checkout that ships with the submodule) is served as a webfont so MathML in the HTML tab renders consistently across browsers. It is the same math font Typst embeds for PDF/SVG. The `@font-face` lives at the top of `static/css/style.css`.

### Typst Template (`src/template.typ`)

All posts import from this shared template. It provides:

- **`blog-post`** — show rule: marginalia layout (40mm outer margin), page headers, fonts (Linux Libertine O + Noto Serif CJK SC), equation numbering, side-captions for figures, title block, table of contents
- **`sidenote[...]`** — unnumbered margin note
- **`note[...]`** — numbered margin note with superscript marker
- **`epigraph[quote][author]`** — pull quote at section openings
- **`newthought[...]`** — small caps paragraph opener
- **`widefig[...]`** — content extending into the margin
- **`notefigure(image(...))`** — figure placed entirely in the margin

Each helper branches on `target() == "html"` (via `context` blocks, since `sys.target` no longer exists in 0.15 and `target()` is contextual). In HTML mode they emit `html.elem(...)` equivalents; helpers that keep labels referenceable (e.g. `notefigure`) mirror marginalia's metadata markers so `@fig:` cross-references keep working. `blog-post` itself runs at evaluation time where `target()` is unavailable, so all target-dependent content is deferred into `context` expressions.

### Post Boilerplate

```typ
#import "../../template.typ": blog-post, sidenote, note, epigraph, newthought, widefig, notefigure

#show: blog-post.with(
  title: "Post Title",
  date: "YYYY-MM-DD",
  tags: ("tag1", "tag2"),
  summary: [Brief description.],
)
```

## Key Conventions

- Post directories: `src/posts/YYYY-MM-DD-slug/` — slug derived by stripping date prefix
- Images: `.webp` format in `images/` subdirectory per post
- Bibliography: `refs.bib` per post directory
- Cross-references: `@eq:label` for equations, `@fig:label` for figures
- Equations auto-numbered via `#set math.equation(numbering: "(1)")`
- Figure captions appear in the margin (Tufte-style), not below the figure
- Use `#newthought[...]` to open new conceptual sections within a heading
- Inter font warning from marginalia is cosmetic — no action needed
- SVG output uses modified Typst for selectable text
