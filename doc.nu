module doc {
  export def main [name?, index?] {
    if ($name != null) {
      let list = $env.LDOC_CURRENT|search $name

      if ($index != null) {
        $list|get $index
      } else {
        $list|summarize
      }
    } else {
      $env.LDOC_CURRENT
    }
  }

  export def-env use [docs] {
    let type = $docs|describe
    if ($type == 'string') {
      $env.LDOC_CURRENT = (open $docs|from yaml)
      $env.PROMPT_COMMAND_RIGHT = { $"using ($docs)" }
    } else {
      $env.LDOC_CURRENT = $docs
    }
  }

  export def download-devdocs-io [name] {
    http get $"https://downloads.devdocs.io/($name).tar.gz"
  }

  export def get-devdocs-io [name] {
    format-devdocs-io (download-devdocs-io $name)|to yaml
  }

  export def format-devdocs-io [archive] {
    let htmldocs = $archive|tar -zx ./db.json -O|complete|get stdout|from json
    let docindex = $htmldocs|(
      items {|key, doc| {$key: (
        if ($doc|query web --query '.section' --as-html) != [] {
          $doc|query web --query '.section' --as-html|
          each {|section| {
            ($section|query web --query '*[id]' -a id|get 0?|default ''): $section
          }}|
          reduce --fold {} {|a, b| $a|merge $b}
        } else {
          let ids = $doc|query web --query '*[id]' -a id

          def find-id-query [id] {
            $'[id="($id)"]'
          }

          def find-id-start [id] {
            $doc|str index-of ($doc|query web --query (find-id-query $id) --as-html|get 0?)
          }

          $ids|each {|id|
            let start = find-id-start $id|default 0
            let endId = $doc|query web --query $"(find-id-query $id) ~ [id]" -a id|get 0?
            let end = if ($endId != null) {
              find-id-start $endId
            } else {
              -1
            }

            [$id ($doc|str substring $start..$end)]
          }|
          reduce --fold {} { |row, memo| $memo|merge {($row|get 0): $row.1} }
        }
      )}}
    )|reduce {|a, b| $a|merge $b}

    let index = $archive|tar -zx ./index.json -O|complete|get stdout|from json

    $index.entries|each {|row|
      let uri = $row.path|parse --regex '(?<doc>[^#]+)(?<hash>#.+)?'|get 0
      let doc = (if ($uri.hash == '' or $uri.hash == null) {
        $htmldocs|get $uri.doc
      } else {
        $docindex|get $uri.doc|get ($uri.hash|str substring 1..)
      })|ldoc-html-to-md

      {
        name: $row.name,
        summary: ($doc|lines|skip until {|line| $line =~ "^\\s*$"}|skip 1|get 0?),
        description: $doc
      }
    }
  }

  def search [name] {
    find $name -c ["name"]
  }

  def show [] {
    less -S --chop-long-lines
  }

  def "from ldoc" [] {
    from yaml
  }

  def summarize [] {
    select name? summary?
  }

  export def from-jsdoc [target] {
    npx jsdoc -X $target|from json|where undocumented? != true|select longname? description? kind? scope? params? returns? type? comment?|rename name summary type
  }
}

use doc