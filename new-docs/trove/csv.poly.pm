#lang pollen

◊(define TL (a-id "TableLoader" (xref "tables" "TableLoader")))



◊(define Opts (a-id "CSVOptions" (xref "csv" "CSVOptions")))

◊docmodule["csv"]{

◊function["csv-table-str"
  #:contract (a-ftype (a-var-type "csv-string" S) (a-var-type "options" Opts) TL)
  #:return TL
  ]{

  Reads CSV data from ◊pyret{csv-str} with the given ◊pyret{options}, returning
  a ◊pyret-id["TableLoader" "tables"] suitable for use with ◊pyret{load-table:}

◊examples{
include csv
animals-data = ```
Pet Name, Age (years), species, fixed
Franklin,17,turtle,false
Veronica,2,cat,false
Ada,10,dog,true
```

check:
  t = load-table: name, age, species, fixed
    source: csv-table-str(animals-data, default-options)
  end
  t is table: name, age, species, fixed
    row: "Franklin", 17, "turtle", false
    row: "Veronica", 2, "cat", false
    row: "Ada", 10, "dog", true
  end
end
}

  }

◊function["csv-table-file"
  #:contract (a-ftype (a-var-type "csv-file" S) (a-var-type "options" Opts) TL)
  #:return TL
  ]{

  Reads CSV data from the file at path ◊pyret{csv-path} with the given ◊pyret{options}, returning
  a ◊pyret-id["TableLoader" "tables"] suitable for use with ◊pyret{load-table:}

  }

◊function["csv-table-url"
  #:contract (a-ftype (a-var-type "csv-file" S) (a-var-type "options" Opts) TL)
  #:return TL
  ]{

  Reads CSV data from the url ◊pyret{csv-url} with the given ◊pyret{options}, returning
  a ◊pyret-id["TableLoader" "tables"] suitable for use with ◊pyret{load-table:}

  ◊examples{
include csv
animals-csv = csv-table-url("https://raw.githubusercontent.com/brownplt/pyret-lang/refs/heads/horizon/tests/io-tests/tests/animals-ds-2024.csv", default-options)
animals-table = load-table: name, species, sex, age, fixed, legs, weight, weeks
  source: animals-csv
end
check:
  animals-table.row-n(0)["name"] is "Sasha"
  animals-table.row-n(0)["species"] is "cat"
end
}

  }
◊type-spec["CSVOptions" (list) #:alias ◊a-record[(a-field "header-row" B)]]

The type of options for processing CSV strings.

◊value["default-options" Opts]

The default options for processing CSV strings.

◊examples{
include csv
check:
  default-options is { header-row: true }
end
}


}

