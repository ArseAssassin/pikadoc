use pkd.nu
use helpers.nu

# Loads all .md files from $path and parses them into a doctable.
export def --env use [path:string] {
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
        |each {
          let file = $in.name
          let md = (open $file)

          {
            name: (
              $md
              |lines
              |where {str starts-with "#"}
              |get 0?
              |default $file
              |pandoc -fgfm -tplain
            )
            kind: 'page'
            id: $file
            defined_in: {
              file: ($file|path expand)
            }
            description: $md
            summary: ($md|helpers markdown-to-summary)
          }
        }
      )
    }
  }
}
