# Advanced filtering

Sometimes we can't find what we need by headlines alone. You can use `doc search` to search through entire symbol definitions:

```nu
# Show all symbols with `use` in the description
doc search 'use'
```

Sometimes it's useful to filter symbols by their header metadata. pikadoc treats doctables as regular nushell values, and as such, regular nushell filters can be used to query them:

```nu
# Show all tables with a column named `date`
doc src:sqlite use ./path-to.db
doc|where {'date' in ($in.columns|get name)}

# To find out more about the help command
where --help
```

When you query symbols with `doc`, the results are transformed to make them easier to read. `doc output --full` can be used to show the raw symbol when planning queries for advanced filters:

```nu
# Get raw data for symbol 0 in current doctable
doc|get 0|doc output --full
```

This covers the basics of reading and generating doctables using pikadoc. The full user guide for pikadoc can be accessed by typing `doc help`. If you're curious about more advanced usage, feel free to keep working through this tutorial.
