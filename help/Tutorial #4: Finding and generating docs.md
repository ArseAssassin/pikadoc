The PikaDoc central repository at the moment holds 150+ ready-made doctables for convenience. To get a list of available docs, you can type:

```nushell
# Show a list of doctables available in the central repository
doc s index
```

To mount one of the doctables for use, you can type `doc s <name>`:

```nushell
# Mount `javascript` documentation for use and shows symbols matching `Intl.dateTimeFormat`
doc s 'javascript'
doc 'Intl.dateTimeFormat'
```

We can also use `src:github` to download documentation for any project on GitHub:

```nushell
# Download and use files available in the pikadoc GitHub repo
doc src:github use 'ArseAssassin/pikadoc'
doc
```

To remind yourself of doctables you've used recently, you can use `doc history`:

```nushell
# Show a list of recently used doctables
doc history
```

To discover more generators, you can search for `doc` commands:

```nushell
# Show a list of usable generators
doc src:nushell use doc
doc pkd-doctable|find src:|find use
```

You can also use the `--help` flag to get help on any generator:

```nushell
# Show usage instructions for `doc src:nushell`
doc src:nushell use --help
```
