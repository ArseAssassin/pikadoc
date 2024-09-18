use pkd.nu
use helpers.nu

def get-name [] {
  lines
  |where {str starts-with "#"}
  |get 0?
  |if ($in != null) {
    pandoc -fgfm -tplain
  }
}

def section-content [] {
  let content = $in

  mut is_codeblock = false
  mut current = ''
  mut sections = []

  for line in ($content|lines) {
    if ($line starts-with '#' and (not $is_codeblock) and $current != '') {
      $sections = ($sections|append $current)
      $current = $line
    } else if ($line starts-with '```') {
      $is_codeblock = not $is_codeblock
      $current = $current + "\n" + $line
    } else {
      $current = $current + "\n" + $line
    }
  }

  $sections|drop 1
}

# Loads all .md files from $path and parses them into a doctable.
export def --env use [
  path:string
  --no-sections
  ] {
  pkd use {
    cd $path
    {
      about: {
        name: $path
        generator: 'src:md'
        text_format: 'markdown'
      },
      doctable: (
        ls **/*.md
        |each {|file|
          let filename = $file.name
          let ns = $filename|path parse|get stem
          let md = (open $filename)

          let sections = if (not ($no_sections)) {
            $md
            |section-content
            |each {|section|
              let name = ($section|get-name|default $section)
              let id = (
                $section
                |lines
                |get 0?
                |default '<span />'
                |pandoc -f gfm -t html
                |hxunent -b
                |xmlstarlet sel -t -v "//@id"
              )
              print -n '.'
              {
                name: $name
                kind: 'section'
                ns: $ns
                id: $"($filename)#($id)"

                description: $section
                summary: ($section|helpers markdown-to-summary)
                belongs_to: $filename
              }
            }
            |reduce --fold [] {|section, sections|
              if ($sections == []) {
                [($section|merge {
                  defined_in: {
                    file: ($filename|path expand)
                    line: 1
                  }
                })]
              } else {
                let last = $sections|last

                $sections
                |append (
                  $section|merge { defined_in: {
                    file: ($filename|path expand)
                    line: ($last.defined_in.line + (
                      $last.description|lines|length
                    ) + 1)
                  }}
                )
              }
            }
          } else {
            []
          }

          [{
            name: $filename
            kind: 'page'
            ns: $ns
            id: $filename
            defined_in: {
              file: ($filename|path expand)
            }
            description: $md
            summary: ($md|helpers markdown-to-summary)
          }] ++ $sections
        }
        |flatten
      )
    }
  }
}
