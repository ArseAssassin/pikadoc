# PikaDoc CLI

PikaDoc is a CLI for generating human-readable, structured and searchable, plaintext reference documentation from your project dependencies. It allows you to search and read documentation from your terminal without touching your browser.

## Demo

```nushell
~: doc src:nushell use doc
~: doc
╭────┬───────────────────────────────────────┬─────────┬────────────────────────────────────────────────────────────────────╮
│  # │                 name                  │  kind   │                              summary                               │
├────┼───────────────────────────────────────┼─────────┼────────────────────────────────────────────────────────────────────┤
│  0 │ doc all                               │ command │ Returns the currently selected doctable without applying any       │
│    │                                       │         │ formatting.                                                        │
│  1 │ doc doc                               │ command │ Returns a summarized table of all available symbols in the         │
│    │                                       │         │ currently selected docfile.                                        │
│  2 │ doc save                              │ command │ Saves doctable in the local filesystem.                            │
│  3 │ doc search                            │ command │ Summarizes current doctable and returns all symbols matching       │
│    │                                       │         │ `$query`                                                           │
│  4 │ doc summarize                         │ command │ Creates a readable summary of a single symbol.                     │
│  5 │ doc summarize-all                     │ command │ Creates a readable summary of all symbols.                         │
│  6 │ doc use                               │ command │ Sets the current doctable.                                         │
│  7 │ doc src:devdocs index                 │ command │ Retrieves a list of available documentation files from devdocs.io  │
│    │                                       │         │ and returns them as a table                                        │
│  8 │ doc src:devdocs use                   │ command │ Downloads and parses documentation from devdocs.io and selects it  │
│    │                                       │         │ as the current doctable                                            │
│  9 │ doc src:javascript parse-from-jsdoc   │ command │ Parses json generated by jsdoc to generate a new doctable.         │
│ 10 │ doc src:javascript use                │ command │ Uses `jsdoc` to generate a doctable from `filepath` and selects is │
│    │                                       │         │  the current doctable                                              │
│ 11 │ doc src:man parse                     │ command │ Parses a roff input into a doctable                                │
│ 12 │ doc src:man use                       │ command │ Parses a man page and selects it as the current doctable           │
│ 13 │ doc src:nushell document-module       │ command │ Returns doctable documenting the named module.                     │
│ 14 │ doc src:nushell use                   │ command │ Generates doctable from nushell module with `name` and selects it  │
│    │                                       │         │ as the current doctable                                            │
│ 15 │ doc src:openapi parse-from-swagger    │ command │ Returns documentation for a REST endpoint defined in a .json/.yaml │
│    │                                       │         │  file.                                                             │
│ 16 │ doc src:openapi use                   │ command │ Generates doctable from `url` to a valid Swagger .json/.ymal file  │
│    │                                       │         │ and selects it as the current doctable                             │
│ 17 │ doc src:python parse-from-sphinx-html │ command │ Parses a doctable from a HTML documentation page generated using   │
│    │                                       │         │ sphinx.                                                            │
│ 18 │ doc src:python use                    │ command │ Parses a HTML documentation page generated using sphinx and        │
│    │                                       │         │ selects it as the current doctable                                 │
│ 19 │ doc src:sqlite parse-from-db          │ command │ Returns documentation for all tables, columns and indexes in a     │
│    │                                       │         │ sqlite database.                                                   │
│ 20 │ doc src:sqlite use                    │ command │ Queries a sqlite database for its tables and selects the output as │
│    │                                       │         │  the current doctable                                              │
╰────┴───────────────────────────────────────┴─────────┴────────────────────────────────────────────────────────────────────╯
~: doc 1
╭───────────────────────┬───────────────────────────────────────────────────────────────────────────────────────────────────╮
│ name                  │ doc doc                                                                                           │
│ summary               │ Returns a summarized table of all available symbols in the currently selected docfile.            │
│                       │ ╭───┬───────┬───────┬──────────────┬──────────╮                                                   │
│ parameters            │ │ # │ type  │ name  │ defaultValue │ optional │                                                   │
│                       │ ├───┼───────┼───────┼──────────────┼──────────┤                                                   │
│                       │ │ 0 │ <any> │ name  │              │ true     │                                                   │
│                       │ │ 1 │ <any> │ index │              │ true     │                                                   │
│                       │ ╰───┴───────┴───────┴──────────────┴──────────╯                                                   │
│ kind                  │ command                                                                                           │
╰───────────────────────┴───────────────────────────────────────────────────────────────────────────────────────────────────╯
Returns a summarized table of all available symbols in the currently selected docfile.

If name is passed as an argument, results will be filtered by their name. If index is passed as an argument, only the
selected result will be returned.

When a single result is found, it'll be presented using doc present. If more than one result is found, returned symbols will
be summarized using doc summarize.
```

## List of features

- rapidly search and filter reference documentation straight from your terminal
- generate reference documentation directly from your project dependencies
- language-agnostic and easily extensible via human-readable YAML files
- docs for 200+ languages and libraries from online sources
- native support for (jsdoc, python, sqlite, man pages and more from local sources)

## Quick start

Follow instructions to [install the Nix package manager](https://nixos.org/download) to your system. Then you can run PikaDoc using:

```bash
nix --experimental-features "nix-command flakes" run "github:ArseAssassin/pikadoc"
```

Once the shell starts, you can list all available documentation sources:

```nushell
# Select pikadoc as the current doctable
doc src:nushell use doc

# List all available doc sources
doc "src:"

# For more information on a specific command
doc "src:" 0
```

To (optionally) install PikaDoc on your system:

```bash
nix --experimental-features "nix-command flakes" profile install "github:ArseAssassin/pikadoc"
pikadoc
```

## More examples
```nushell
~: # Parse man pages for command line options for xargs
~: doc src:man use xargs; doc
╭───────┬─────────────────────────────────┬───────────┬─────────────────────────────────────────────────────────────────────╮
│     # │              name               │   kind    │                               summary                               │
├───────┼─────────────────────────────────┼───────────┼─────────────────────────────────────────────────────────────────────┤
│     0 │ -0, --null                      │ option    │ Input  items  are  terminated  by a null character instead of by    │
│       │                                 │           │ whitespace, and the quotes and backslash are not special  (every    │
│       │                                 │           │ character is taken literally)                                       │
│     1 │ -a file, --arg-file=file        │ option    │ Read items from file instead of standard input                      │
│     2 │ --delimiter=delim, -d delim     │ option    │ Input  items  are  terminated  by  the specified character          │
╰───────┴─────────────────────────────────┴───────────┴─────────────────────────────────────────────────────────────────────╯
...

~: # Parse swagger.json for rest endpoints
~: doc src:openapi use "https://petstore.swagger.io/v2/swagger.json"; doc
╭───┬───────────────────────────────┬───────────────┬────────────────────────────╮
│ # │             name              │     kind      │          summary           │
├───┼───────────────────────────────┼───────────────┼────────────────────────────┤
│ 0 │ POST /pet/{petId}/uploadImage │ rest-endpoint │ uploads an image           │
│ 1 │ POST /pet                     │ rest-endpoint │ Add a new pet to the store │
│ 2 │ GET /pet/findByStatus         │ rest-endpoint │ Finds Pets by status       │
╰───┴───────────────────────────────┴───────────────┴────────────────────────────╯
...

~: # Query sqlite database for tables
~: doc src:sqlite use media-arc.db; doc 1
╭─────────┬─────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ name    │ files                                                                                                           │
│         │ ╭───┬──────────────────┬─────────┬──────────────┬──────────┬───────╮                                            │
│ columns │ │ # │       name       │  type   │ defaultValue │ nullable │  pk   │                                            │
│         │ ├───┼──────────────────┼─────────┼──────────────┼──────────┼───────┤                                            │
│         │ │ 0 │ path             │ TEXT    │              │ false    │ true  │                                            │
│         │ │ 1 │ data             │ json    │              │ false    │ false │                                            │
│         │ │ 2 │ mime             │ TEXT    │              │ false    │ false │                                            │
│         │ │ 3 │ date             │ TEXT    │              │ false    │ false │                                            │
│         │ │ 4 │ rating           │ INTEGER │ 0            │ false    │ false │                                            │
│         │ │ 5 │ created_by_index │ TEXT    │              │ false    │ false │                                            │
│         │ │ 6 │ title            │ TEXT    │              │ true     │ false │                                            │
│         │ │ 7 │ thumbnail        │ BLOB    │              │ true     │ false │                                            │
│         │ ╰───┴──────────────────┴─────────┴──────────────┴──────────┴───────╯                                            │
│ source  │ CREATE TABLE files (path text primary key not null, data json not null, mime text not null, date text not null, │
│         │  rating integer default 0 not null, created_by_index text not null references file_indexes, title text,         │
│         │ thumbnail blob)                                                                                                 │
│ kind    │ table                                                                                                           │
╰─────────┴─────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
...

# Parse Python documentation
~: doc src:python use "https://flask.palletsprojects.com/en/3.0.x/api/"; doc
╭───┬───────────────────────────┬────────┬──────────────────────────────────────────────────────────────────────────────────╮
│ # │           name            │  kind  │                                     summary                                      │
├───┼───────────────────────────┼────────┼──────────────────────────────────────────────────────────────────────────────────┤
│ 0 │ Flask                     │ class  │ The flask object implements a WSGI application and acts as the central object.   │
│   │                           │        │ It is passed the name of the module or package of the application. Once it is    │
│   │                           │        │ created it will act as a central registry for the view functions, the URL rules, │
│   │                           │        │  template configuration and much more.                                           │
│ 1 │ Flask.add_template_filter │ method │ Register a custom template filter. Works exactly like the template_filter()      │
│   │                           │        │ decorator.                                                                       │
│ 2 │ Flask.add_template_global │ method │ Register a custom template global function. Works exactly like the               │
│   │                           │        │ template_global() decorator.                                                     │
╰───┴───────────────────────────┴────────┴──────────────────────────────────────────────────────────────────────────────────╯
...

# Parse HTML documentation from devdocs.io
~: doc src:devdocs use react
~: doc useState
╭─────────┬──────────╮
│ name    │ useState │
╰─────────┴──────────╯
┄┄┄useState

────────────────────
const [state, setState] = useState(initialState);
────────────────────

Returns a stateful value, and a function to update it.

During the initial render, the returned state (state) is the same as the value passed as the first argument (initialState).

The setState function is used to update the state. It accepts a new state value and enqueues a re-render of the component.
...
```

### Why use PikaDoc over Zeal/DevDocs/Google etc.?

PikaDoc is not a replacement for existing documentation systems, but a supportive tool - it aims to do two things well: allow you to point at a symbol and answer the question "what is this" as well as provide complete listings of all available symbols in a given language/library/system. It provides a distraction-free, structured view of what you're looking for and allows you to query and filter documentation symbols any way you wish.

PikaDoc is not reliant on any single web service, cloud platform, etc. It's designed to be rapidly extensible by running inside a shell environment. You can pipe in data from any source, making it essentially language-agnostic - you can generate PikaDoc definitions using any language you like.

PikaDoc files are human-readable and self-contained, which makes them an easy way to add supportive documentation into your git repository. They're easy to generate and cache locally, making them accessible 24/7 - even when you're on the go.

### Can I use PikaDoc without Nix?

Yes, by manually installing its dependencies. At the time of writing this, this consists of `mdcat`, `pandoc`, `nushell` and `groff`, as well as the [nushell query plugin](https://github.com/nushell/nushell/tree/main/crates/nu_plugin_query). You can then clone this repo and call `use ./doc/` to use pikadoc functions.

I fully recommend trying out Nix though, for it is fantastic.
