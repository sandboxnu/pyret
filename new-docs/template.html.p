<!doctype html>
<html lang="en">
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-sRIl4kxILFvY47J16cr9ZwB07vP4J8+LH7qKQnuqkuIAvNWLzeN8tE5YBujZqJLB" crossorigin="anonymous">
  <script src="https://ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/js/bootstrap.bundle.min.js" integrity="sha384-FKyoEForCGlyvwx9Hj09JcYn3nv7wiPVlz7YYwJrWVcXK/BmnVDxM+D2scQbITxI" crossorigin="anonymous"></script>
  <script src="◊(prefix-dir (point-to-project-root here) (symbol->string './pollenboots/codemirror.js))"></script>
  <script src="◊(prefix-dir (point-to-project-root here) (symbol->string './pollenboots/runmode.js))"></script>
  <script src="◊(prefix-dir (point-to-project-root here) (symbol->string './pollenboots/pyret.js))"></script>
  <script src="◊(prefix-dir (point-to-project-root here) (symbol->string './pollenboots/hilite.js))"></script>
  <script src="◊(prefix-dir (point-to-project-root here) (symbol->string './pollenboots/search.js))"></script>
  <script src="◊(prefix-dir (point-to-project-root here) (symbol->string './pollenboots/pyret_2.js))"></script>
  <script src="◊(prefix-dir (point-to-project-root here) (symbol->string './pollenboots/default-rpcs.js))"></script>
  <script type="module" src="◊(prefix-dir (point-to-project-root here) (symbol->string './pollenboots/embed-api.js))"></script>
  <script src="◊(prefix-dir (point-to-project-root here) (symbol->string './pollenboots/scribble-common.js))"></script>
  <link rel="stylesheet" type="text/css" href="◊(prefix-dir (point-to-project-root here) (symbol->string './pollenboots/codemirror.css))" title="default"/>
  <link rel="stylesheet" type="text/css" href="◊(prefix-dir (point-to-project-root here) (symbol->string './pollenboots/pyret.css))" title="default"/>
  <link rel="stylesheet" type="text/css" href="◊(prefix-dir (point-to-project-root here) (symbol->string './styles.css))" title="default"/>
  <head>
    <title>◊(doc-title doc)</title>
  </head>
  <body>
    <form class="searchform" id="searchformid"><input class="searchbox" id="searchbox" type="text" tabindex="1" placeholder="...search manuals..." title="Enter a search string to search the manuals" onkeypress="return DoSearchKey(event, this, &quot;9.1&quot;, &quot;&quot;);"/></form>
    <div class="container">
    ◊(->html doc)
    ◊(define top-dir (point-to-project-root here))
    ◊(define prev-page (prefix-dir top-dir (previous here)))
    ◊(define next-page (prefix-dir top-dir (next here)))
    <hr/>
    <!-- The current page is ◊|here|. -->
    ◊when/splice[prev-page]{
    <a class="floatleft" href="◊prev-page">⏴⏴⏴</a>
    }
    ◊when/splice[next-page]{
    <a class="floatright" href="◊next-page">⏵⏵⏵</a>
    }
    </div>
  </body>
</html>
