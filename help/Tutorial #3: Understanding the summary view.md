When `doc` returns a doctable, instead of showing full documentation it shows you a summarized view of the documentation symbols found. By default, search results are limited to 20 - to show more results you can type in `doc more`.

You can filter `doc` results by passing in a string as a query:

```nushell
doc 'src:'
```

The result list view includes the column `#` as the index of the symbol. To view the full text for a symbol, you can pass `#` as an argument to `doc`:

```nushell
doc 0

# You can also pipe the output to a pager to make reading longer decriptions easier:
doc 0|less
```
