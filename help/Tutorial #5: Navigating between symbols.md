# Navigating between symbols

Numeric IDs can be difficult to memorize when switching between multiple symbols. The `doc history` command can be used to see a reminder which symbols you've viewed recently.

```nushell
# Show a summarized list of recent symbols
doc history
```

It can be useful to bookmark certain symbols for future reference. You can use `doc bookmarks` for that.

```nushell
# Bookmark symbols 10 and 11
doc bookmarks add 10
doc bookmarks add 11

# Show a list of all bookmarks for current doctable
doc bookmarks
```

To see a list of recently used doctables, you can use `doc history doctables`.

```nushell
# Show a list of recently used doctables
doc history doctables
```
