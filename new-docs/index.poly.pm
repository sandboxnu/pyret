#lang pollen

◊(define VERSION 0)

◊title[#:version (number->string ◊VERSION)]{Pyret}

◊nested{This document has detailed information on the Pyret grammar and the
behavior of its expression forms and built-in libraries, along with many
examples and some longer descriptions of language design choices. If you want
to do something in a program and you can't find how in this document, feel free
to post a message on the
◊link["https://groups.google.com/forum/#!forum/pyret-discuss" "Pyret discussion
list"], and we'll be happy to help.}

◊nested{If you want to learn about (or teach!) programming and computer science
using Pyret, check out ◊link["https://dcic-world.org" "A Data Centric Introduction to Computing"], which is a textbook on programming starting with
Pyret.}

◊nested{Previous release notes documents have useful information on major
updates over time.}

◊ul[
  ◊li{◊hyperlink["https://www.pyret.org/release-notes/2025.html"]{Summer 2025}}
  ◊li{◊hyperlink["https://www.pyret.org/release-notes/summer-2021.html"]{Summer 2021}}
  ◊li{◊hyperlink["https://www.pyret.org/release-notes/summer-2020.html"]{Summer 2020}}
  ◊li{◊hyperlink["https://groups.google.com/g/pyret-discuss/c/kUr3iIYsheE/m/Z7FTW9ZcEwAJ"]{Fall 2017}}
  ◊li{◊hyperlink["https://groups.google.com/g/pyret-discuss/c/n4yAxubXHyY/m/EJr0yMlwAAAJ"]{Fall 2016}}
  ◊li{◊hyperlink["https://groups.google.com/g/pyret-discuss/c/i1qMU_YP9Tw/m/j67PlQx0CQAJ"]{Summer 2016}}
  ◊li{◊hyperlink["https://www.pyret.org/release-notes/v0.5.html"]{Summer 2014}}
]

◊include-section{getting-started.poly.pm}

◊include-section{language-concepts.poly.pm}

◊include-section{libraries.poly.pm}

◊include-section{style-guide.poly.pm}

◊include-section{internal.poly.pm}

◊include-section{glossary.poly.pm}

◊pollen-postlude[]
