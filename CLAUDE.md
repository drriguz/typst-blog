# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A Tufte-style blog system built with [Typst](https://typst.app). Posts are written in Typst's markup language and compiled to PDF using the [marginalia](https://typst.app/universe/package/marginalia) package for wide margins, sidenotes, and margin figures.

## Build Commands

```bash
# Compile a single post (from project root)
typst compile --root . src/posts/<name>/post.typ

# Watch mode for live preview
typst watch --root . src/posts/<name>/post.typ

# Example: compile the Bayes post
typst compile --root . src/posts/bayes/post.typ
```

Output PDFs are generated alongside `post.typ` in each post directory.

## Architecture

```
src/
├── template.typ          # Shared Tufte-style template (marginalia, typography, helpers)
└── posts/
    └── <topic>/
        ├── post.typ      # Blog post content
        ├── refs.bib      # Bibliography (BibTeX)
        └── images/       # Post-specific images (.webp)
```

### Template (`src/template.typ`)

All posts import from this shared template. It provides:

- **`blog-post`** — show rule that sets up marginalia layout (40mm outer margin), page headers, fonts, equation numbering, and side-captions for figures
- **`sidenote[...]`** — unnumbered margin note (most common)
- **`note[...]`** — numbered margin note with superscript marker
- **`epigraph[quote][author]`** — pull quote at section openings
- **`newthought[...]`** — small caps paragraph opener (Tufte convention)
- **`widefig[...]`** — content extending into the margin area
- **`notefigure(image(...))`** — figure placed entirely in the margin

### Post boilerplate

Every post starts with:
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

- Images use `.webp` format, stored in `images/` subdirectory per post
- Bibliography files are named `refs.bib` per post directory
- Cross-references: `@eq:label` for equations, `@fig:label` for figures
- Equations auto-numbered via `#set math.equation(numbering: "(1)")`
- Figure captions appear in the margin (Tufte-style), not below the figure
- Use `#newthought[...]` to open new conceptual sections within a heading
- Inter font warning from marginalia is cosmetic — no action needed
