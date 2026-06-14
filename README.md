# typst-blog

A Tufte-style static blog generator powered by **Typst**. Write posts in Typst with wide margins, sidenotes, margin figures, and epigraphs — inspired by Edward Tufte's book design.

## Features

- Tufte-style PDF output via [marginalia](https://typst.app/universe/package/marginalia): wide margins, sidenotes, margin figures, side-captions
- HTML output via Typst SVG with **selectable text** (modified Typst compiler)
- Epigraphs, small caps (`newthought`), numbered equations
- Bibliography support (BibTeX)
- Tag-based organization with index and tag pages
- CLI for creating new posts, building, and previewing

## Prerequisites

- **Rust** (1.70+): <https://rustup.rs/>
- **Git submodules**: `git submodule update --init --recursive`

## Quick Start

```bash
# Clone with submodules
git clone --recursive https://github.com/drriguz/typst-blog.git
cd typst-blog

# Build the static site (builds modified Typst automatically)
make build

# Preview locally at http://localhost:9527
make serve

# Create a new post
make new

# Build then serve
make dev
```

Or use cargo directly (requires `typst-modified` binary):

```bash
# Build modified Typst first
make typst-modified

# Then build blog
cargo run -- new "My Post Title" --tags "math,algorithms"
cargo run -- build
cargo run -- serve --port 9527
```

## Writing a Post

Each post lives in `src/posts/YYYY-MM-DD-slug/`:

```
src/posts/2026-01-15-bayes-theorem/
├── post.typ      # Post content
├── refs.bib      # Bibliography
└── images/       # Post-local images (.webp)
```

A post starts with:

```typ
#import "../../template.typ": blog-post, sidenote, note, epigraph, newthought, widefig, notefigure

#show: blog-post.with(
  title: "My Post Title",
  date: "2026-01-15",
  tags: ("math", "probability"),
  summary: [A brief description.],
)

= Introduction

Write your content here. Use #sidenote[margin notes] for tangential context.
```

### Template Helpers

| Function | Description |
|---|---|
| `sidenote[...]` | Unnumbered margin note |
| `note[...]` | Numbered margin note |
| `epigraph[quote][author]` | Pull quote at section openings |
| `newthought[...]` | Small caps paragraph opener |
| `widefig[...]` | Content extending into the margin |
| `notefigure(image(...))` | Figure in the margin |

### Images

```typ
// Margin figure
#notefigure(
  image("images/diagram.webp"),
  caption: [A small figure in the margin.],
)

// Wide figure (extends into margin)
#widefig[
  #figure(
    image("images/chart.webp"),
    caption: [A wide figure.],
  )
]
```

### Math

```typ
Inline: $E = m c^2$

Display (auto-numbered):
$ integral_{-infinity}^{infinity} e^{-x^2} dif x = sqrt(pi) $ <eq:gauss>

Reference: see @eq:gauss.
```

### Citations

```typ
According to @knuth1997, ...

#bibliography("refs.bib", style: "ieee")
```

## Build Pipeline

1. Scan `src/posts/*/post.typ` for metadata
2. Per post: Typst → PDF (full Tufte layout) + SVG (selectable text)
3. SVGs embedded in HTML template
4. Generate index and tag pages
5. Copy images and static assets to `output/`

## SVG Text Selection

The HTML output uses a modified Typst compiler that renders text as SVG `<text>` elements instead of `<use>` elements referencing glyph shapes. This makes the text:

- **Selectable** — users can select and copy text
- **Searchable** — browser find (Ctrl+F) works
- **Accessible** — screen readers can read the text

To use this feature, place the modified Typst binary as `typst-modified` in the project root.

## Project Structure

```
├── src/
│   ├── template.typ              # Shared Tufte-style template
│   └── posts/YYYY-MM-DD-slug/   # Blog posts
├── templates/                    # HTML templates (Tera)
├── static/css/style.css          # Site stylesheet
├── src/                          # Rust CLI source
├── output/                       # Generated site (gitignored)
├── typst-modified                # Modified Typst binary (selectable text)
├── Cargo.toml
└── Makefile
```

## License

MIT
