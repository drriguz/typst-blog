# typst-blog

A Tufte-style static blog generator powered by **Typst**. Write posts in Typst with wide margins, sidenotes, margin figures, and epigraphs — inspired by Edward Tufte's book design.

## Features

- Tufte-style PDF output via [marginalia](https://typst.app/universe/package/marginalia): wide margins, sidenotes, margin figures, side-captions
- HTML output via Typst SVG rendering (pixel-perfect, same as PDF)
- Epigraphs, small caps (`newthought`), numbered equations
- Bibliography support (BibTeX)
- Tag-based organization with index and tag pages
- CLI for creating new posts, building, and previewing
- No Pandoc dependency — Typst does everything

## Prerequisites

- **Rust** (1.70+): <https://rustup.rs/>
- **Typst** (0.14+): `brew install typst`

## Quick Start

```bash
# Build the static site
make build

# Preview locally at http://localhost:9527
make serve

# Create a new post
make new

# Build then serve
make dev
```

Or use cargo directly:

```bash
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
2. Per post: Typst → PDF + SVG (one per page)
3. SVGs embedded in HTML template
4. Generate index and tag pages
5. Copy images and static assets to `output/`

## Project Structure

```
├── src/
│   ├── template.typ              # Shared Tufte-style template
│   └── posts/YYYY-MM-DD-slug/   # Blog posts
├── templates/                    # HTML templates (Tera)
├── static/css/style.css          # Site stylesheet
├── src/                          # Rust CLI source
├── output/                       # Generated site (gitignored)
├── Cargo.toml
└── Makefile
```

## License

MIT
