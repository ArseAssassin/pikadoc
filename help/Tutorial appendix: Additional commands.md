# Appendix: Additional commands

Here are some additional commands you might find useful:

```nushell
# Save a doctable in the filesystem
doc save './doctable.pkd'

# View source code for symbol §0
doc 0|doc view-source

# Return a list of doctables cached in the local filesystem
doc cache

# Delete cached doctables
doc cache clear

# Show metadata about the currently mounted doctable
doc pkd-about
```
