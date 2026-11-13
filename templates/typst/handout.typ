#import "./compiled-cover.typ": render-compiled-cover
#import "./partials/metadata.typ": render-title-block
#import "./partials/toc.typ": render-toc
#import "./partials/section-openers.typ": section-heading-block

#let conf(
  title: none,
  subtitle: none,
  authors: (),
  date: none,
  lang: "en",
  region: "US",
  font: (),
  fontsize: 11pt,
  mode: "convert",
  cover: false,
  toc: false,
  toc_depth: 2,
  doc,
) = {
  let accent = rgb("#21492C")
  let muted = rgb("#54645A")
  let base-font = if font == () { ("Helvetica",) } else { font }

  set document(
    title: title,
    author: authors.map(author => author.name),
  )
  set page(
    paper: "us-letter",
    margin: (top: 0.92in, bottom: 0.92in, left: 1in, right: 1in),
    numbering: "1",
  )
  set text(
    font: base-font,
    size: 12pt,
    lang: lang,
    region: region,
    fill: rgb("#1F2F24"),
  )
  set par(justify: false, leading: 0.86em)

  show heading.where(level: 1): it => section-heading-block(it, accent, mode)
  show heading.where(level: 2): it => [
    #block(above: 1.15em, below: 0.55em)[
      #text(size: 1.18em, weight: "semibold", fill: accent)[#it.body]
    ]
  ]

  if mode == "compiled" and cover {
    render-compiled-cover(
      title: title,
      subtitle: subtitle,
      authors: authors,
      date: date,
      accent: accent,
      muted: muted,
    )
    pagebreak()
  } else if mode == "compiled" {
    render-title-block(
      title: title,
      subtitle: none,
      authors: authors,
      date: date,
      accent: accent,
      muted: muted,
    )
  } else {
    render-title-block(
      title: title,
      subtitle: subtitle,
      authors: authors,
      date: date,
      accent: accent,
      muted: muted,
    )
  }

  if toc {
    render-toc(depth: toc_depth)
    pagebreak(weak: true)
  }

  doc
}
