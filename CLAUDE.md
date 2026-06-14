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
   - **PDF**: `typst compile --root . --format pdf` → full Tufte layout with marginalia
   - **SVG**: `typst-modified compile --root . --format svg` → selectable text via `<text>` elements
   - **Images**: copy `images/` to `output/posts/<slug>/images/`
4. Generate `output/index.html` and `output/tags/<tag>/index.html`
5. Copy `static/` to `output/`

### Modified Typst Binary

The `typst-modified` binary is built from the `typst-src/` submodule (fork at github.com/drriguz/typst). It renders text as SVG `<text>` elements instead of `<use>` elements, making text selectable and searchable in browsers.

Key changes in Typst source (`crates/typst-svg/src/text.rs`):
- `render_text()` checks if all glyphs are outline glyphs
- If so, calls `render_text_as_svg_text()` which emits `<text>` with `<tspan>` children
- Falls back to `<use>` elements for color/image glyphs

Build: `make typst-modified` (compiles from `typst-src/` submodule)

### Typst Template (`src/template.typ`)

All posts import from this shared template. It provides:

- **`blog-post`** — show rule: marginalia layout (40mm outer margin), page headers, fonts, equation numbering, side-captions for figures, title block, table of contents
- **`sidenote[...]`** — unnumbered margin note
- **`note[...]`** — numbered margin note with superscript marker
- **`epigraph[quote][author]`** — pull quote at section openings
- **`newthought[...]`** — small caps paragraph opener
- **`widefig[...]`** — content extending into the margin
- **`notefigure(image(...))`** — figure placed entirely in the margin

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
