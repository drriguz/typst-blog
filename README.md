# typst-blog

A Tufte-style static blog template powered by **Typst**. Features wide margins, sidenotes, margin figures, and epigraphs — inspired by Edward Tufte's book design.

## Features

- **Tufte-style layout** — wide margins for sidenotes, figures, and annotations
- **PDF + HTML output** — PDF for download, HTML with selectable text for browsing
- **Math support** — equations rendered beautifully with Typst
- **Bibliography** — BibTeX citations support
- **Tags** — organize posts with tag-based navigation
- **Auto deploy** — GitHub Actions builds and deploys on push

## Quick Start

### 1. Use this template

Click "Use this template" on GitHub, or clone:

```bash
git clone --recursive https://github.com/YOUR_USERNAME/typst-blog.git my-blog
cd my-blog
```

### 2. Install prerequisites

- [Rust](https://rustup.rs/) (1.70+)
- [Git](https://git-scm.com/) (for submodules)

### 3. Build and preview

```bash
# Build everything (first run downloads fonts and compiles modified Typst)
make build

# Preview locally
make serve
# Open http://localhost:9527
```

Fonts are downloaded automatically on first build:
- **Source Han Sans SC** — Chinese text
- **FiraMath** — Math symbols
- **Cascadia Code** — Code blocks

### 4. Create your first post

```bash
make new
# Enter title when prompted
```

This creates `src/posts/YYYY-MM-DD-your-title/post.typ`. Edit it and rebuild.

## Writing Posts

Each post lives in `src/posts/YYYY-MM-DD-slug/`:

```
src/posts/2026-01-15-my-post/
├── post.typ      # Post content
├── refs.bib      # Bibliography (optional)
└── images/       # Images (optional)
```

### Post template

```typ
#import "../../template.typ": blog-post, sidenote, note, epigraph, newthought, widefig, notefigure

#show: blog-post.with(
  title: "My Post Title",
  date: "2026-01-15",
  tags: ("topic1", "topic2"),
  author: "Your Name",
  summary: [Brief description shown on index page.],
)

= Introduction

Your content here. Use #sidenote[margin notes] for side comments.

= Math Example

Inline math: $E = m c^2$

Display math with numbering:
$ integral_0^infinity e^{-x^2} dif x = sqrt(pi) / 2 $ <eq:gauss>

Reference equations: see @eq:gauss.

= Code

```python
def hello():
    print("Hello, World!")
```

= Conclusion

Wrap up your post here.
```

### Available helpers

| Function | Description |
|---|---|
| `sidenote[text]` | Unnumbered margin note |
| `note[text]` | Numbered margin note |
| `epigraph[quote][author]` | Pull quote at section opening |
| `newthought[text]` | Small caps paragraph opener |
| `widefig[content]` | Content extending into margin |
| `notefigure(image(...))` | Figure in the margin |

### Images

```typ
// Margin figure
#notefigure(
  image("images/diagram.webp"),
  caption: [Description.],
)

// Wide figure (extends into margin)
#widefig[
  #figure(
    image("images/chart.webp"),
    caption: [Description.],
  )
]
```

### Citations

Add references to `refs.bib`:

```bibtex
@book{knuth1997,
  author = {Knuth, Donald E.},
  title = {The Art of Computer Programming},
  year = {1997},
}
```

Cite in your post:

```typ
According to @knuth1997, ...
```

## Customize

### Change site name and author

Edit `templates/base.html`:

```html
<a href="{{ root_path }}" class="site-title">
    <img src="{{ root_path }}Yoda.png" alt="Logo" class="site-logo">
    Your Blog Name
</a>
```

Edit `src/template.typ` default author:

```typ
#let blog-post(
  ...
  author: "Your Name",
  ...
)
```

### Change logo

Replace `static/Yoda.png` with your own image.

### Change colors

Edit `static/css/style.css`:

```css
:root {
    --color-link: #1a5276;        /* Link color */
    --color-bg: #fffff8;          /* Background */
    --content-width: 36rem;       /* Text width */
}
```

### Fonts

The blog uses these open-source fonts (downloaded automatically):

| Font | Purpose | Source |
|------|---------|--------|
| Source Han Sans SC | Chinese text | [Adobe](https://github.com/adobe-fonts/source-han-sans) |
| FiraMath | Math symbols | [FiraMath](https://github.com/firamath/firamath) |
| Cascadia Code | Code blocks | [Microsoft](https://github.com/microsoft/cascadia-code) |
| Times New Roman | English text | System font |

To change fonts, edit `src/template.typ` and `templates/base.html`.

## Deployment

### GitHub Actions (recommended)

1. Go to repo → Settings → Secrets → Actions
2. Add these secrets:

| Secret | Description | Example |
|--------|-------------|---------|
| `DEPLOY_HOST` | Server hostname | `example.com` |
| `DEPLOY_PORT` | SSH port | `22` |
| `DEPLOY_USER` | SSH username | `deploy` |
| `DEPLOY_PATH` | Remote directory | `/var/www/blog/` |
| `DEPLOY_KEY` | SSH private key | See below |

3. Generate SSH key:

```bash
ssh-keygen -t ed25519 -C "github-deploy" -f ~/.ssh/blog-deploy
ssh-copy-id -i ~/.ssh/blog-deploy.pub user@your-server
# Copy private key content to DEPLOY_KEY secret
cat ~/.ssh/blog-deploy
```

4. Push to `main` — automatic deployment!

For detailed setup (server config, Nginx, permissions), see [Deployment Guide](docs/deploy-guide.md).

### Manual deployment

```bash
make build
rsync -avzr --delete output/ user@server:/var/www/blog/
```

## Commands

```bash
make build          # Build the site
make serve          # Preview at http://localhost:9527
make new            # Create new post
make dev            # Build + serve
make clean          # Remove output/
make deploy         # Build + deploy via rsync
```

## Project Structure

```
├── src/
│   ├── template.typ              # Tufte-style Typst template
│   └── posts/YYYY-MM-DD-slug/   # Blog posts
├── templates/                    # HTML templates
├── static/                       # CSS, images, fonts
├── typst-src/                    # Modified Typst (git submodule)
├── .github/workflows/            # CI/CD
├── Cargo.toml                    # Rust dependencies
└── Makefile                      # Build commands
```

## How it works

1. Posts are written in Typst (`.typ` files)
2. Modified Typst compiler generates SVG with selectable text
3. SVG is embedded in HTML template with navigation
4. PDF is also generated for download
5. GitHub Actions builds and deploys on push

## Requirements

- **Rust** 1.70+
- **Typst** (bundled as submodule, no separate install needed)

## License

MIT
