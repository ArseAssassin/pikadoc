Sometimes we can't find what we need by headlines alone. You can use `doc search` to search through entire symbol definitions:

```nushell
# Show all symbols with `zip` in the description
doc search 'zip'
```

Sometimes it's useful to filter symbols by their header metadata. A closure can be passed to `doc` query any field in the full doctable.

```nushell
# Show all tables with a column named `date`
doc src:sqlite use ./path-to.db
doc {|| where {'date' in ($in.columns|get name)}}
```

When you query symbols with `doc`, the results are transformed to make them easier to read. `doc pkd-doctable` can be used to access raw symbols for planning queries for advanced filters:

```nushell
# Get raw data for symbol 0 in current doctable
doc pkd-doctable|get 0
```

This covers the basics of reading and generating doctables using pikadoc. If you're curious about advanced usage, feel free to keep working through this tutorial.
