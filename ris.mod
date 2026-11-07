# `ris get example.com/someone/lib` adds a dependency here.
module github.com/domify/sqlite

require github.com/domify/db v0.3.1 as db

replace github.com/domify/db => ../db
