def peek [name?=''] {
  let it = $in
  print $"($name): ($it)"
  $it
}
def header-row [name] {
  { name: $name
    items: [] }
}

def parse-from-help [help: string] {
  let docLines = $help|ansi strip|lines
  let parsed = (
    $docLines|reduce --fold [(header-row description)] {|row, memo|
      let header = $row|parse '{name}:'|get 0?.name?

      if ($header != null) {
        $memo|append (header-row $header)
      } else {
        let len = ($memo|length)
        $memo|take ($len - 1)|append ($memo|get ($len - 1)|update items {|| append $row})
      }
    }
  )|reduce --fold {} {|row, memo|
    {
      $row.name: ($row.items|str join "\n")
    }|merge $memo
  }

  {
    name: ($parsed.Usage|parse --regex '\s+> (?<name>[^\s]+)'|get 0.name)
    summary: ($parsed.description|lines|get 0?)
    description: $parsed.description
    parameters: (
      $parsed.Parameters?
      |default ''
      |lines
      |each {|line|
        let it = (
          $line
          |str trim
          |parse --regex "(?<name>[^\\s]+) (?<type>[^:]+):[\\s]*(?<meta>.*)"
          |get 0?
        )

        if ($it == null) {
          print $line
        }

        {
          type: $it.type
          name: $it.name
          defaultValue: ($it.meta|parse --regex 'default: (?<value>[^)]+)'|get 0?.value?|default null)
          optional: ('optional,' in $it.meta)
        }
      }
    )
    kind: 'command'
  }
}

def get-help-for-command [cmd: string] {
  nu -c $"use ($env.PKD_PATH); ($cmd) --help|to nuon" --plugin-config ($env.HOME + "/.config/pikadoc/plugin.nu")|from nuon
}

# Returns doctable documenting the named module.
#
# `name` is the name of the module to document
# `path` is the path to the submodule. If module is a top-level module, path should be `[]`
export def document-module [name, path=[]] {
  let modPath = ([$name]|prepend $path)|str join ' '
  let mod = scope modules|where name == $name
  let commands = $mod|get commands|get 0?|default []
  let submodules = $mod|get submodules|get 0?|default []

  $commands
  |(each {|row|
    let cmdPath = $"($modPath) ($row.name)"
    parse-from-help (get-help-for-command $cmdPath)
    | update name $cmdPath
  })
  | append (
    $submodules
    |each {|submodule| document-module $submodule.name ($name|append $path) }
    |flatten
  )
}

export def-env use [name] {
  $env.PKD_CURRENT = (document-module $name)
  $env.PKD_ABOUT = {
    name: $name
    text_format: 'plain'
    generator: 'src:man'
  }
}