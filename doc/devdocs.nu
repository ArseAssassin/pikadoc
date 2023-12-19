def download [name] {
  http get $"https://downloads.devdocs.io/($name).tar.gz"|to yaml
}

def format [archive:binary] {
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

export def save-to-file [name, file] {
  format (download $name)|save -f file
}
