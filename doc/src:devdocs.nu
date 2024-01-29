def download [name] {
  let url = $"https://downloads.devdocs.io/($name).tar.gz"
  print $"Downloading ($url)"
  let it = http get $url
  print "Download finished"
  $it
}

def format [archive:binary] {
  print "Extracting data"
  let htmldocs = $archive|tar -zx ./db.json -O|complete|get stdout|from json
  let docindex = $htmldocs|
    (
    items {|key, doc|
      { key: $key, doc: $doc }
    }
    |par-each {|item|
      let key = $item.key
      let doc = $item.doc
      print -n .
      let sections = $doc|query web --query '.section' --as-html
      {$key: (
        if ($sections != []) {
          $doc|query web --query '.section' --as-html|
          each {|section|
            let ids = $section|query web --query '*[id]' -a id
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

          $ids
          |zip (($ids|skip 1) ++ null)
          |reduce --fold {currentDoc: $doc, values: []} {|ids, acc|
            print -n .

            let id = $ids|get 0
            let endId = $ids|get 1
            let doc = $acc.currentDoc
            let start = find-id-start $id

            if ($start == (-1)) {
              return { currentDoc: $doc, values: ($acc.values ++ [[$id $doc]]) }
            }

            let end = if ($endId != null) {
              find-id-start $endId
            } else {
              null
            }

            let output = $doc|str substring $start..$end
            { currentDoc: ($doc),
              values: ($acc.values ++ [[$id $output]]) }

          }
          |get values
          |reduce --fold {} { |row, memo| $memo|merge {($row|get 0): $row.1} }
        }
      )}
    }
  )
  |reduce {|a, b| $a|merge $b}
  print ''

  let entries = (
    $archive
    |tar -zx ./index.json -O
    |complete
    |get stdout
    |from json
    |get entries
  )

  print $"Converting ($entries|length) HTML pages"

  $entries
  |par-each {|row|
    print -n '.'
    let uri = $row.path|parse --regex '(?<doc>[^#]+)(?<hash>#.+)?'|get 0
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

    if ($doc|str trim|is-empty) {
      {}
    } else {
      {
        name: $row.name,
        summary: (
          $doc
          |lines
          |skip until {|line| $line =~ "^[A-z]"}
          |get 0?
          |default ''
          |split column '.'
          |get column1?.0?
          |default ''
          |pandoc -f gfm -t plain --wrap=none),
        description: $doc
      }
    }
  }
}

def html-to-md [] {
  pandoc -f html -t gfm-raw_html --wrap=none
}

# Retrieves a list of available documentation files from devdocs.io and returns them as a table
export def index [] {
  http get https://devdocs.io/docs.json
  |select name slug version? links?.home?
}

# Downloads and parses documentation from devdocs.io and selects it as the current doctable
#
# `slug` is the url slug of the documentation file. Use src:devdocs index for a complete list of available files
#
# Example: doc src:devdocs use nushell
#
# See also: doc src:devdocs index
#
# NOTE: Since this function downloads and parses a lot of HTML data, it can be quite slow - make sure to use `doc save` to cache frequently used doctables locally.
export def --env use [slug] {
  $env.PKD_CURRENT = (format (download $slug))
  $env.PKD_ABOUT = {
    name: $slug
    text_format: 'markdown'
    generator: 'src:devdocs'
  }
  print ''
  print ("Done! Remember to cache results locally using `doc save`"|mdcat)
}
