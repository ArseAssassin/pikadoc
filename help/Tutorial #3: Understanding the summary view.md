# Understanding the summary view

By default, search results returned by `doc` are limited to 20 - to show more results you can type in `doc more`.

```nushell
# Show more results from your last query
doc more
```

To search for a specific query, you can use `doc <query>`

```nushell
# Show search results matching 'src:'
doc 'src:'
```

The result list view includes the column `#` as the index of the symbol. To view the full text for a symbol, you can pass `#` as an argument to `doc`:

```nushell
doc 0
```
