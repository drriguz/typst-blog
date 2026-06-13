// ─── Tufte-style Blog Template ─────────────────────────────────────
// Import this in each post:
//   #import "../template.typ": blog-post, sidenote, note, epigraph, newthought, widefig, notefigure
//   #show: blog-post.with(title: "...", date: "...", tags: (...), summary: "...")[...]

#import "@preview/marginalia:0.3.1" as marginalia: note as _note, notefigure as _notefigure, wideblock as _wideblock

// ─── Main show rule ────────────────────────────────────────────────
#let blog-post(
  title: "",
  date: "",
  tags: (),
  summary: none,
  body,
) = {
  // Marginalia layout
  show: marginalia.setup.with(
    outer: ( far: 5mm, width: 40mm, sep: 5mm ),
    book: false,
    clearance: 12pt,
  )

  // Document metadata
  set document(title: title)

  // Page layout
  set page(
    numbering: "1",
    header: context {
      let elems = query(heading.where(level: 1))
      let current = elems.filter(h => h.location().page() <= here().page()).last()
      text(size: 8pt, fill: gray, style: "italic")[#current.body #h(1fr) #counter(page).display("1")]
    },
  )

  // Typography
  set text(lang: "en", size: 11pt, font: ("New Computer Modern", "Songti SC"))
  set par(justify: true, leading: 0.8em)
  set heading(numbering: none)
  set math.equation(numbering: "(1)")

  // Side-captions for figures (Tufte-style)
  set figure(gap: 0pt)
  set figure.caption(position: top)
  show figure.caption.where(position: top): _note.with(
    alignment: "top", counter: none, shift: "avoid", keep-order: true, dy: -0.01pt,
  )

  // ─── Title block ─────────────────────────────────────────────────
  heading(level: 1, outlined: false)[#title]
  v(0.3em)
  text(size: 9pt, fill: gray)[#date · #tags.join(", ")]
  if summary != none {
    v(0.4em)
    block(inset: (left: 0pt))[
      #set text(size: 10pt)
      #set par(justify: true)
      #summary
    ]
  }
  v(0.6em)

  body
}

// ─── Sidenotes ─────────────────────────────────────────────────────
// Unnumbered margin note (most common in Tufte style)
#let sidenote = _note.with(counter: none)

// Re-export numbered note for when you want the marker
#let note = _note

// Re-export notefigure
#let notefigure = _notefigure

// ─── Wide block (alias) ───────────────────────────────────────────
#let widefig = _wideblock

// ─── Epigraph ──────────────────────────────────────────────────────
#let epigraph(quote, author) = {
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

// ─── New thought (small caps paragraph opener) ─────────────────────
#let newthought(body) = {
  v(0.3em)
  smallcaps(body)
}
