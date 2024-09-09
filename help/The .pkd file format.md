`pkd` is a simple YAML-based file format consisting of two sections: header and the body. The two sections are separated by the YAML `---` document marker. While the format doesn't limit what kind of metadata can be stored, there are certain conventions to be followed to get good results from pkd-readers.

Note that pikadoc is still a work-in-progress, and these specifications are likely to change and become more detailed in the future.

## The header section

The header section consists of the following fields:

- `name` - name of the documentation target. This should be recognizable as the name of the library/framework/language you're documenting. PikaDoc users should be able to use this to pick your doctable from a list, as if picking a book from a bookshelf
- `version` - version number of your documentation target. Users can use this to recognize whether their documentation is up to date
- `text_format (markdown/rst/text)` - format of the symbol descriptions. Helps pkd-readers figure out how to format the text body. Markdown is used commonly, some readers may also support ReStructuredText. If reader doesn't support the given format, it'll fall back on plain text
- `homepage` - homepage of your documentation target. Often this will be a URL to the GitHub repo
- `generator` - name of the generator used to create this file. If file was created manually, use `manual`
- `license` - license notice for this documentation. Should match the license of your repository. Can be the same as the contents of your `LICENSE.txt`, or shorthand for the license like `MIT`

Some **optional header fields** are useful for updating and archiving pkd files:

- `description` - long text description of your documentation target. Can be the same as the contents of your `README.md`
- `summary` - one line explanation of your documentation target
- `generator_command` - command used to generate this documentation. Users can refer to this to generate up to date documentation against your repo
- `generator_homepage` - homepage of the generator. Users can use this download latest version for generating up to date documentation

## The body section

The body of a pkd-file consists of a list of documentation symbols with the following required fields:

- `name` - name of the documented symbol. For things like class methods, class name should be included. Should be unique in its namespace
- `ns` - namespace of the documented symbol. This should include things like package/module/file name, informing users how to import the symbol for use
- `kind` - a string value of what of symbol this is. Some valid values include: `function`, `class`, `method`, `property`, `module`, `table`, `const`. Note that this is *not the type of the symbol*: if you have a constant with the type string, this value should be `const`, not `string`

These fields are technically optional (pkd readers should consider them valid symbols), but are strongly encouraged to be included:

- `description` - free text description of what this symbol is. Can use the markup format defined in the header field `text_format` for rich text formatting
- `summary` - a single line plain text description of what this symbol is. Shown next to the name when searching through the doctable

These fields are optional, but extremely helpful for end users:

- `signatures` - list of type signatures if your symbol is a `function`, `method`, `command` or other type of callable. To support language features such as method overloading, this value is a list of lists consisting of parameters, ending with a return value. That is to say, each type signature is a list of objects with the following optional fields:
  - `name` - name of the parameter
  - `description` - description of what the parameter is
  - `type` - type of the parameter, following your language's type system
  - `kind` - kind of the parameter. Some valid values include: `positional`, `return`, `rest`, `flag`, etc. Should follow your language's conventions
  - `default` - string representation of the default value for this parameter. `null` if it doesn't have one
- `inherits_from` - if this symbol is a class, list of classes this symbol inherits from.
