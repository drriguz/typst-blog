// ─── Tufte-style Blog Template ─────────────────────────────────────
// Import this in each post:
//   #import "../template.typ": blog-post, sidenote, note, epigraph, newthought, widefig, notefigure
//   #show: blog-post.with(title: "...", date: "...", tags: (...), summary: "...")[...]
//
// The template adapts to the export target:
//   - paged (PDF/SVG): marginalia place-based margin notes, page headers
//   - html: semantic HTML (<aside>/<span>) positioned by the site CSS
// Typst has no hoisting, so helpers are defined before they are used.

#import "@preview/marginalia:0.3.1" as marginalia: note as _note, notefigure as _notefigure, wideblock as _wideblock

// ─── Paged helpers (defined first) ─────────────────────────────────
#let _paged-sidenote = _note.with(counter: none)

#let _paged-note = _note.with(
  numbering: marginalia.note-numbering.with(
    style: text.with(weight: 900, font: ("Linux Libertine O", "Noto Serif CJK SC"), size: 5pt, style: "normal", fill: rgb(54%, 72%, 95%)),
  ),
)

#let _paged-epigraph(quote, author) = {
  v(0.5em)
  block(width: 80%)[
    #set text(size: 10pt, style: "italic")
    #set par(justify: true)
    #quote
    #linebreak()
    #set text(style: "normal")
    --- #author
  ]
  v(0.8em)
}

#let _paged-newthought(body) = {
  v(0.3em)
  smallcaps(body)
}

#let _paged-title-block(title, date, tags, summary, author) = {
  heading(level: 1, outlined: false)[#title]
  v(0.3em)
  text(size: 9pt, fill: gray)[#author · #date · #tags.join(", ")]
  if summary != none {
    v(0.4em)
    block(inset: (left: 0pt))[
      #set text(size: 10pt)
      #set par(justify: true)
      #summary
    ]
  }
  v(0.6em)
}

#let _paged-toc() = {
  block(inset: (left: 0pt, right: 0pt))[
    #set text(size: 9pt)
    #set par(leading: 0.6em)
    #outline(title: [Contents], indent: 1.2em)
  ]
  v(0.8em)
}

// ─── Main show rule ────────────────────────────────────────────────
#let blog-post(
  title: "",
  date: "",
  tags: (),
  summary: none,
  author: sys.inputs.at("author", default: "Author"),
  body,
) = {
  // Marginalia layout (paged only; in HTML export the page set rule
  // inside is ignored with a warning, everything else passes through)
  show: marginalia.setup.with(
    outer: ( far: 5mm, width: 40mm, sep: 5mm ),
    book: false,
    clearance: 12pt,
  )

  // Document metadata (HTML: → <head> meta; PDF: → document info)
  set document(
    title: title,
    description: summary,
    author: (author,),
    keywords: tags,
  )

  // Page layout (paged only; ignored with a warning in HTML export)
  set page(
    numbering: "1",
    header: context {
      let elems = query(heading.where(level: 1))
      let current = elems.filter(h => h.location().page() <= here().page()).last()
      text(size: 8pt, fill: gray, style: "italic")[#current.body #h(1fr) #counter(page).display("1")]
    },
  )

  // Typography - Linux Libertine with CJK fallback
  set text(lang: "en", size: 11pt, font: ("Linux Libertine O", "Noto Serif CJK SC"))
  set par(justify: true, leading: 0.8em)
  set heading(numbering: none)
  set math.equation(numbering: "(1)")

  // Side-captions for figures (Tufte-style); HTML keeps native captions
  set figure(gap: 0pt)
  set figure.caption(position: top)
  show figure.caption.where(position: top): it => context {
    if target() == "html" {
      it
    } else {
      _note.with(
        alignment: "top", counter: none, shift: "avoid", keep-order: true, dy: -0.01pt,
      )(it)
    }
  }

  // Displayed equations: the native HTML rule omits numbering markers,
  // so wrap them in a container and emit the number from the counter.
  show math.equation.where(block: true): it => context {
    if target() == "html" {
      let n = counter(math.equation).at(it.location()).first()
      html.elem("div", attrs: (class: "eq-display"), [
        #it
        #html.elem("span", attrs: (class: "eq-num"), numbering("(1)", n))
      ])
    } else {
      it
    }
  }

  // TOC entries (strong, paged only)
  show outline.entry.where(level: 1): it => context {
    if target() == "html" {
      it
    } else {
      v(0.3em)
      strong(it)
    }
  }

  // ─── Title block + table of contents ────────────────────────────
  context {
    if target() == "html" {
      let summary-block = if summary != none {
        html.elem("div", attrs: (class: "post-summary-block"), summary)
      }
      html.elem("header", attrs: (class: "post-title-block"), [
        #html.elem("h1", title)
        #html.elem("div", attrs: (class: "post-subline"), [#author · #date · #tags.join(", ")])
        #summary-block
      ])
      outline(title: [Contents], indent: 1.2em)
    } else {
      _paged-title-block(title, date, tags, summary, author)
      _paged-toc()
    }
  }

  body
}

// ─── Sidenotes ─────────────────────────────────────────────────────
// Unnumbered margin note (most common in Tufte style)
#let sidenote(body) = context {
  if target() == "html" {
    html.elem("span", attrs: (class: "sidenote"), body)
  } else {
    _paged-sidenote(body)
  }
}

// Numbered margin note with superscript marker.
// In HTML mode the marker is an empty <sup> and the number is rendered
// by CSS counters (see style.css) so marker and note always match.
#let note(body, ..rest) = context {
  if target() == "html" {
    html.elem("sup", attrs: (class: "note-ref")) + html.elem("span", attrs: (class: "sidenote numbered"), body)
  } else {
    _paged-note(body, ..rest)
  }
}

// Notefigure: figure placed entirely in the margin.
//
// The leading metadata marker is emitted unconditionally so that a label
// attached to the notefigure call binds to a sequence (not a bare
// context), which marginalia's ref show rule recognizes. In HTML mode
// the figure is wrapped in an <aside> and a derived label/meta pair
// mirrors marginalia's structure so cross-references keep working.
#let notefigure(content, ..figureargs) = {
  [#metadata("_marginalia_notefigure") <_marginalia_notefigure>]
  context {
    if target() == "html" {
      let index = query(selector(<_marginalia_notefigure>).before(here())).len()
      let figure-label = label("_marginalia_notefigure__" + str(index))
      html.elem(
        "aside",
        attrs: (class: "margin-fig"),
        [
          #figure(content, gap: 0.55em, ..figureargs)#figure-label
          #metadata((label: figure-label)) <_marginalia_notefigure_meta>
        ],
      )
    } else {
      _notefigure(content, ..figureargs)
    }
  }
}

// ─── Wide block (alias) ───────────────────────────────────────────
#let widefig(body) = context {
  if target() == "html" {
    html.elem("div", attrs: (class: "wide-fig"), body)
  } else {
    _wideblock(body)
  }
}

// ─── Epigraph ──────────────────────────────────────────────────────
#let epigraph(quote, author) = context {
  if target() == "html" {
    html.elem("blockquote", attrs: (class: "epigraph"), [
      #html.elem("p", attrs: (class: "epigraph-quote"), quote)
      #html.elem("p", attrs: (class: "epigraph-author"), "— " + author)
    ])
  } else {
    _paged-epigraph(quote, author)
  }
}

// ─── New thought (small caps paragraph opener) ─────────────────────
#let newthought(body) = context {
  if target() == "html" {
    html.elem("span", attrs: (class: "newthought"), smallcaps(body))
  } else {
    _paged-newthought(body)
  }
}
