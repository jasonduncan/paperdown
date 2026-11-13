#let render-compiled-cover(title: none, subtitle: none, authors: (), date: none, accent: rgb("#16324F"), muted: rgb("#5A6573")) = [
  #align(center + horizon)[
    #block(inset: (top: 6em, bottom: 2em))[
      #text(size: 0.85em, tracking: 0.18em, fill: accent)[COMPILED DOCUMENT]
      #v(1.4em)
      #text(size: 2.35em, weight: "bold", fill: accent)[#title]
      #if subtitle != none [
        #v(0.9em)
        #text(size: 1.05em, fill: muted)[#subtitle]
      ]
      #v(1.6em)
      #if authors != none and authors != [] [
        #text(size: 0.95em, fill: muted)[#authors.map(author => author.name).join(", ")]
      ]
      #if date != none [
        #v(0.5em)
        #text(size: 0.9em, fill: muted)[#date]
      ]
    ]
  ]
]
