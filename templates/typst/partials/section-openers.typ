#let section-heading-block(it, accent, mode) = {
  if mode == "compiled" {
    [
      #pagebreak(weak: true)
      #block(above: 0em, below: 0.9em)[
        #text(size: 0.75em, tracking: 0.16em, fill: accent)[SECTION]
        #parbreak()
        #text(size: 1.45em, weight: "bold", fill: accent)[#it.body]
      ]
    ]
  } else {
    [
      #block(above: 1.4em, below: 0.7em)[
        #text(size: 1.35em, weight: "bold", fill: accent)[#it.body]
      ]
    ]
  }
}
