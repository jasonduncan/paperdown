#let render-title-block(title: none, subtitle: none, authors: (), date: none, accent: rgb("#16324F"), muted: rgb("#5A6573")) = [
  #if title != none [
    #text(size: 1.8em, weight: "bold", fill: accent)[#title]
    #parbreak()
  ]
  #if subtitle != none [
    #text(size: 1em, fill: muted)[#subtitle]
    #parbreak()
  ]
  #if authors != none and authors != [] [
    #text(size: 0.95em, fill: muted)[#authors.map(author => author.name).join(", ")]
    #parbreak()
  ]
  #if date != none [
    #text(size: 0.9em, fill: muted)[#date]
    #parbreak()
  ]
  #v(1.2em)
]
