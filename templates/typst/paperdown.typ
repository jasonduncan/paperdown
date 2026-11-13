#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#show terms.item: it => block(breakable: false)[
  #text(weight: "bold")[#it.term]
  #block(inset: (left: 1.5em, top: -0.4em))[#it.description]
]

#set table(
  inset: 6pt,
  stroke: none,
)

#show figure.where(
  kind: table,
): set figure.caption(position: $if(table-caption-position)$$table-caption-position$$else$top$endif$)

#show figure.where(
  kind: image,
): set figure.caption(position: $if(figure-caption-position)$$figure-caption-position$$else$bottom$endif$)

$if(highlighting-definitions)$
// syntax highlighting functions from skylighting:
$highlighting-definitions$

$endif$
$if(smart)$
$else$
#set smartquote(enabled: false)

$endif$
$for(header-includes)$
$header-includes$

$endfor$

$if(paperdown_style)$
#import "$paperdown_style$.typ": conf
$else$
#import "report.typ": conf
$endif$

#show: doc => conf(
$if(title)$
  title: [$title$],
$endif$
$if(subtitle)$
  subtitle: [$subtitle$],
$endif$
$if(author)$
  authors: (
$for(author)$
$if(author.name)$
    ( name: "$author.name$",
      affiliation: "$author.affiliation$",
      email: "$author.email$" ),
$else$
    ( name: "$author$",
      affiliation: "",
      email: "" ),
$endif$
$endfor$
    ),
$endif$
$if(date)$
  date: "$date$",
$endif$
$if(lang)$
  lang: "$lang$",
$endif$
$if(region)$
  region: "$region$",
$endif$
$if(mainfont)$
  font: ("$mainfont$",),
$endif$
$if(fontsize)$
  fontsize: $fontsize$,
$endif$
  mode: "$if(paperdown_mode)$$paperdown_mode$$else$convert$endif$",
  cover: $if(paperdown_cover)$$paperdown_cover$$else$false$endif$,
  toc: $if(toc)$true$else$false$endif$,
  toc_depth: $if(toc-depth)$$toc-depth$$else$2$endif$,
  doc,
)

$body$
