# Returns doctable documenting the named module.
#
# `name` is the name of the module to document
def document-module [name:string] {
  scope commands
  |where name starts-with $name
  |each {{
    name:         $"($in.name)"
    summary:      ($in.usage|str trim)
    kind:         command
    description:  ($"($in.usage)\n\n($in.extra_usage)"|str trim)
    source:       (try {
                    view source $in.name
                  })
    examples: (
      try {
        $in.examples?
        |each { $"```nu\n# ($in.description)\n($in.example)\n# -> ($in.result|to nuon)\n```" }
      }
    )
    signatures: (
      $in.signatures
      |items {|output, args|
        $args
        |each {
          let arg = $in
          {
            name: $arg.parameter_name
            type: (if ($arg.parameter_type == 'switch') {
              'bool'
            } else {
              $arg.syntax_shape
            })
            description: $arg.description
            optional: $arg.is_optional
            default: $arg.parameter_default
            kind: (match $arg.parameter_type {
              'input' => 'input'
              'positional' => 'positional'
              'switch' => 'flag'
              'named' => 'named'
              'output' => 'return'
            })
          }
        }
      }
    )
  }}
}

# Generates doctable from nushell module with `name` and selects it as the current doctable
#
# Example: doc src:nushell use "doc"
export def --env use [
  name:string # the name of the module to document
  ] {
  do --env $env.DOC_USE {
    about: {
      name: (
        if ($name != '') {
          $name
        } else {
          'nushell all'
        }
      )
      text_format: 'markdown'
      generator: 'src:nushell'
    }
    doctable: (document-module $name)
  }
}