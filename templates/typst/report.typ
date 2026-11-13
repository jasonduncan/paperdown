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
  let accent = rgb("#16324F")
  let muted = rgb("#5A6573")
  let base-font = if font == () { ("Palatino",) } else { font }

  set document(
    title: title,
    author: authors.map(author => author.name),
  )
  set page(
    paper: "us-letter",
    margin: (top: 1in, bottom: 1in, left: 1.05in, right: 1.05in),
    numbering: "1",
  )
  set text(
    font: base-font,
    size: fontsize,
    lang: lang,
    region: region,
    fill: rgb("#1D2B38"),
  )
  set par(justify: false, leading: 0.72em)

  show heading.where(level: 1): it => section-heading-block(it, accent, mode)
  show heading.where(level: 2): it => [
    #block(above: 1.1em, below: 0.45em)[
      #text(size: 1.12em, weight: "semibold", fill: accent)[#it.body]
    ]
  ]
  show quote: it => block(
    inset: (left: 1.2em),
    stroke: (left: 1.2pt + muted),
    fill: rgb("#F5F7FA"),
    radius: 4pt,
  )[
    #set text(style: "italic", fill: muted)
    #it.body
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
