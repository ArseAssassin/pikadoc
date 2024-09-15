# Understanding the summary view

By default, `doc` displays a summarized list of symbols, limited to 20 search results. `doc page` can be used to browse search results:

```nushell
# Show more results from your last query
doc page next

# `doc more` is an alias of `doc page next`
doc more
```

To search for a specific query, you can use `doc <query>`

```nushell
# Show search results matching 'src:'
doc 'src:'
```

The result list view includes the column `§` as the index of the symbol. To view the symbol, select it from the table:

```nushell
# Show full description for symbol §0
doc 0

# Symbol can be selected from a list as well
doc|get 0
doc|first
```
