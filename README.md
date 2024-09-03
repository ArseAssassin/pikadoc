# PikaDoc

PikaDoc is a human-readable, structured documentation format. `pkd`-files don't ship as HTML files, but as already indexed data tables, ready to be explored on the command line or your browser.

Currently there are two PikaDoc clients: the `pikadoc` CLI maintained in this repository and the [web interface](https://tuomas.kanerva.info/pkdocs/) for reading docs stored in the [pkDocs central repository](https://github.com/ArseAssassin/pkdocs/tree/main/docs).

## Quick start

### PikaDoc CLI

`pikadoc` uses Nix for packaging. To run the CLI, first [install Nix](https://nixos.org/download/#download-nix) using your preferred method, then run:

```bash
nix --experimental-features "nix-command flakes" run "github:ArseAssassin/pikadoc"
```

You can (optionally) add `pikadoc` to your path by doing:

```bash
nix --experimental-features "nix-command flakes" profile install "github:ArseAssassin/pikadoc"
```

The best way to learn `pikadoc` is by going through the interactive tutorial:

```nushell
# Guides you through the pikadoc tutorial while inside the `pikadoc` shell
doc tutor
```

The tutorial can also be viewed under the [`help/` directory](help/).

### PikaDoc web

`pkd`s available in the PikaDoc central repository can also be viewed using the [web client](https://tuomas.kanerva.info/pkdocs/).

## Why PikaDoc?

Development of PikaDoc is motivated by one belief: all code that runs on your computer should have version-specific offline documentation available. To bring about this vision, we encourage developers to add a `DOCS.pkd` to the root of their repo. [Here's an example](DOCS.pkd) of what it looks like. `pkd` is a simple, YAML-based file format that remains human-readable without any special reader software: accessing it is as simple as doing `less repo/DOCS.pkd`.

To assist in bringing this about, PikaDoc CLI provides a number of modules out of the box for generating documentation from offline as well as online sources:

#### `doc s`

The pkDocs central repository holds documentation for 200+ technologies that are immediately ready to download for use. See [here](https://github.com/ArseAssassin/pkdocs/tree/main/docs) for a full listing. These are also available using the [web client](https://tuomas.kanerva.info/pkdocs/).

```nushell
> doc s javascript
```

#### `doc src:github`

Downloads all `md` files from a GitHub repository and indexes them by filename.

```nushell
> doc src:github use ArseAssassin/pikadoc
```

#### `doc src:man`

Parses available command line flags from manpages installed locally.

```nushell
> doc src:man use curl
```

#### `doc src:sqlite`

Given an sqlite file, generates doctable from all tables and columns.

```nushell
> doc src:sqlite use ./path-to.db
```

#### `doc src:openapi`

Generates documentation from a Swagger API definition file.

```nushell
> doc src:openapi use "https://petstore.swagger.io/v2/swagger.json"
```

#### `doc src:nushell`

Generates documentation from commands available in the current nushell session.

```nushell
> doc src:nushell use "doc"
```

### Is this a replacement for README files?

Absolutely not! README files are great - when they're well written and maintained, they can act as fantastic guides explaining how to use the repo. They come with a sizable downside though: maintaining reference documentation can be an unwieldy task. Largely because of this, many projects end up creating their own online documentation portals, or worse, leave large parts of the codebase undocumented to the public. This is where PikaDoc comes in.

With the `pkd` file format, project maintainers can generate accurate and up-to-date reference documentation straight from the sources. The files are already indexed and searchable, making all parts of the codebase instantly discoverable to the end user.

## License

This project is made available under the MIT license. See the `LICENSE` file for more information.
