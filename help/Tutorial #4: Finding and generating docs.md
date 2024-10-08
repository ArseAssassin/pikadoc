# Finding and generating docs

A great place to start looking for documentation is the PikaDoc central repository. It holds 150+ doctables, pre-generated for your convenince. To get a full list of featured documentation, you can use `doc s index`.

```nu
# Show a list of doctables available in the central repository
doc s index
```

To use a doctable from the central repository, you can type `doc s use <name>`:

```nu
# Mount `javascript` documentation for use
doc s use 'javascript'

# Show symbols matching `Intl.dateTimeFormat`
doc 'Intl.dateTimeFormat'
```

We can also use `src:github` to download documentation for any project on GitHub:

```nu
# Mount `javascript` documentation for use
doc s use 'javascript'

# Show symbols matching `Intl.dateTimeFormat`
doc 'Intl.dateTimeFormat'
```

```nu
# Download and use files available in the pikadoc GitHub repo
doc src:github use 'ArseAssassin/pikadoc'
doc
```

To discover more generators, you can list all available documentation sources:

```nu
# Show a list of usable generators
doc src:nushell use doc
doc 'src:'
```

You can also use the `--help` flag to get help on any generator:

```nu
# Show usage instructions for `doc src:nushell`
doc src:nushell use --help
```
