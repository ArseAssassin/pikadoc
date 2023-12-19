module doc {
  export def main [name?, index?] {
    if (($name|describe) == 'int') {
      $env.PKD_CURRENT|get $name|present
    } else if ($name != null) {
      let list = $env.PKD_CURRENT|search $name

      if ($index != null) {
        $list|get $index|present
      } else {
        $list|present-list
      }
    } else {
      $env.PKD_CURRENT|present-list
    }
  }

  def present-list [] {
    if ($in|length) == 1 {
      $in|get 0|present
    } else {
      $in|summarize-all
    }
  }

  export def-env use [docs] {
    let type = $docs|describe
    if ($type == 'string') {
      $env.PKD_CURRENT = (open $docs|from yaml)
      $env.PROMPT_COMMAND_RIGHT = { $"using ($docs)" }
    } else {
      $env.PKD_CURRENT = $docs
    }
  }

  def download-devdocs-io [name] {
    http get $"https://downloads.devdocs.io/($name).tar.gz"
  }

  def get-devdocs-io [name] {
    format-devdocs-io (download-devdocs-io $name)|to yaml
  }

  def format-devdocs-io [archive:binary] {
    let htmldocs = $archive|tar -zx ./db.json -O|complete|get stdout|from json
    let docindex = $htmldocs|(
      items {|key, doc|
        let sections = $doc|query web --query '.section' --as-html
        print $key
        {$key: (
        if ($sections != []) {
          $doc|query web --query '.section' --as-html|
          each {|section|
            let ids = $section|query web --query '*[id]' -a id
            print $ids
            {
              ($ids|get 0?|default ''): ($section)
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
            let start = find-id-start $id

            if ($start == (-1)) {
              return [$id $doc]
            }

            let endId = $doc|query web --query $"(find-id-query $id) ~ [id]" -a id|get 0?
            let end = if ($endId != null) {
              find-id-start $endId
            } else {
              -1
            }

            print $"id ($id) start ($start) end ($end)"

            [$id ($doc|str substring $start..$end)]
          }|
          reduce --fold {} { |row, memo| $memo|merge {($row|get 0): $row.1} }
        }
      )}}
    )|reduce {|a, b| $a|merge $b}

    let index = $archive|tar -zx ./index.json -O|complete|get stdout|from json

    $index.entries|each {|row|
      let uri = $row.path|parse --regex '(?<doc>[^#]+)(?<hash>#.+)?'|get 0
      print $uri
      let doc = if ($uri.hash == '' or $uri.hash == null or $uri.hash == '#_') {
        $htmldocs|get $uri.doc|html-to-md
      } else {
        let baseDoc = $docindex|get -i $uri.doc
        if ($baseDoc == null) {
          return ''
        }

        let idDoc = $baseDoc|get -i ($uri.hash|str substring 1..)

        if ($idDoc == null) {
          $htmldocs|get $uri.doc|html-to-md
        } else {
          $idDoc|html-to-md
        }
      }

      {
        name: $row.name,
        summary: ($doc|lines|skip until {|line| $line =~ "^\\s*$"}|skip 1|get 0?),
        description: $doc
      }
    }
  }

  export def get-from-devdocs-io [name, file] {
    get-devdocs-io $name|save -f file
  }

  def search [name] {
    find $name -c ["name"]
  }

  def show [] {
    less -S --chop-long-lines
  }

  def "from pkd" [] {
    from yaml
  }

  def summarize [] {
    select name? summary?|trim-record-whitespace
  }

  def summarize-all [] {
    each {|| summarize}
  }

  def map-record-values [block: closure] {
    items $block|reduce --fold {} {|a, b| $b|merge $a}
  }

  def trim-record-whitespace [] {
    map-record-values {|key, value| {
      $key: (if (($value|describe) == 'string') {
        $value|str trim
      } else {
        $value
      })
    }}
  }

  export def from-jsdoc [target] {
    from json|where undocumented? != true|select longname? description? kind? scope? params? returns? type? comment?|rename name summary type
  }

  def html-to-md [] {
    pandoc --from=html --to=gfm-raw_html
  }

  def present [] {
    trim-record-whitespace
    |maybe-update type {|| str join ' -> '}
    |maybe-update parameters {|| each {|| trim-record-whitespace }}
  }

  def maybe-update [name, value] {
    if ($in|get -i $name) != null {
      update $name $value
    } else {
      $in
    }
  }
}

use doc