Sometimes we can't find what we need by headlines alone. You can use `doc search` to search through entire symbol definitions:

```nushell
# Show all symbols with `zip` in the description
doc search 'zip'
```

Many generators insert metadata that can be useful for querying. `doc pkd-doctable` can be used to create custom filters:

```nushell
# Show all tables with a column named `date`
doc src:sqlite use ./path-to.db
doc pkd-doctable|where {'date' in ($in.columns|get name)}
```
