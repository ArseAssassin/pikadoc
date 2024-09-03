def parse-section [name] {
  let lines = (
    $in
    |ansi strip
    |lines
    |skip until {|it| $it == $name}
    |skip 1
    |take until {|it| $it =~ '^[A-Z\s]+$'}
  )

  if ($lines == []) {
    return []
  }

  let lineNumbers = (
    0..(($lines|length) - 1)
    |filter {|i|
      let line = $lines|get $i

      $line|default ''|str starts-with '       -'
    }
  )

  $lineNumbers
  |zip ($lineNumbers|skip 1)
  |each {|it|
    let start = $it.0
    let end = $it.1 - $start - 1
    let body = (
      $lines
      |skip ($start + 1)
      |take $end
      |each {|| str trim }
      |str join "\n"
      |str trim
    )

    {
      name: ($lines|get $start|str trim)
      summary: (
        $body
        |split column '.'
        |get column1?.0?
      )
      description: $body
      kind: option
    }
  }
}

def trim-whitespace [] {
  let it = $in
  if ($it =~ '\s\s') {
    $it|str replace -a -r '\s\s' " "|trim-whitespace
  } else {
    $it
  }
}

# Parses a roff input into a doctable
#
# `$in` is a valid string in roff format
#
# Example: man -Rutf8 man|doc src:man parse
export def parse [] {
  let doc = $in
  ($doc|parse-section OPTIONS) ++ ($doc|parse-section DESCRIPTION)
}

# Parses a man page and selects it as the current doctable
#
# Takes the name of the manual entry as an argument and parses the command line options for that entry. The generated doctable is selected as the current doctable.
#
# `$it` is the name of the man page
#
# Example: doc src:man use "cat"
export def --env use [it:string] {
  let generatorCommand = $"src:man use ($it)"
  do --env $env.DOC_USE {{
    about: {
      name: $it
      text_format: 'plain'
      generator: 'src:man'
      generator_command: $generatorCommand
    }
    doctable: (man -Rutf8 $it|do {groff -man -T utf8}|complete|get stdout|parse)
  }} $generatorCommand
}