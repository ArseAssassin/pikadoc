# Reading pikadocs

The simplest possible pikadoc command is `doc`. If you try running it now, you should see a notice telling you that no doctable has been selected for use. To change that, we can run a pikadoc generator to mount one:

```nushell
doc src:nushell use doc
```

The above command generates documentation for the `doc` nushell module. All pikadoc commands are exposed under this module. To get a list of all the commands, you can again run `doc`.

```nushell
# Show a list of symbols in the current doctable
doc
```
