#import "../../template.typ": blog-post, sidenote, note, epigraph, newthought, widefig, notefigure

#show: blog-post.with(
  title: "__TITLE__",
  date: "__DATE__",
  tags: ("__TAGS__"),
  author: "Riguz Lee",
  summary: [A brief summary of the post.],
)

// ─── Epigraph (optional) ───────────────────────────────────────────
// #epigraph[
//   A relevant quote here.
// ][
//   Author Name
// ]

= Introduction

Write your introduction here. Use #sidenote[margin notes] for tangential context.

= Main Content

Your main content goes here. You can use:

== Math

Inline math: $E = m c^2$.

Display math:
$ integral_{-infinity}^{infinity} e^{-x^2} dif x = sqrt(pi) $

== Code

```python
def hello():
    print("Hello, World!")
```

== Tables

#table(
  columns: 3,
  stroke: none,
  align: center,
  table.header(
    [*Name*], [*Value*], [*Unit*],
  ),
  table.hline(stroke: 0.5pt),
  [Speed of light], [$3 times 10^8$], [m/s],
  [Planck constant], [$6.626 times 10^(-34)$], [J·s],
  table.hline(stroke: 0.5pt),
)

== Images

// Margin figure:
// #notefigure(
//   image("images/example.webp"),
//   caption: [A margin figure.],
// )

// Wide figure:
// #widefig[
//   #figure(
//     image("images/example.webp"),
//     caption: [A wide figure extending into the margin.],
//   )
// ]

= Conclusion

Write your conclusion here.

// ─── Bibliography ──────────────────────────────────────────────────
// #bibliography("refs.bib", style: "ieee")
