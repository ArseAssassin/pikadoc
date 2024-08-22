def normalize-html [] {
  hxnormalize -x
}

def download [name] {
  let url = $"https://downloads.devdocs.io/($name).tar.gz"
  print $"Downloading ($url)"
  let it = http get $url
  print "Download finished"
  $it
}

def is-inline-section [] {
  let section = $in

  'h1 h2 h3 h4 h5 h6 br span p'
  |split words
  |any {|elem| $section|str starts-with $"<($elem)"}
}

def format [archive:binary] {
  print "Extracting data"
  let htmldocs = $archive|tar -zx ./db.json -O|complete|get stdout|from json
  let docindex = $htmldocs|
    (
    items {|key, doc|
      { key: $key, doc: $doc }
    }
    |each {|item|
      let key = $item.key
      let doc = $item.doc
      print -n .
      print $key

      $doc
      |query web --query '[id]' --as-html
      |each {|section|
        let sectionId = $section|normalize-html|query web --query '[id]' -a id|get 0
        { $"($key)#($sectionId)": (
          if ($section|is-inline-section) {
            let subdoc = $doc|str substring ($doc|str index-of $section)..

            $subdoc|str substring ..(
              $subdoc|str index-of ($subdoc|query web --query $"[id]:not\([id='($sectionId)']\)" --as-html|get 0?|default 'dasofuisdaofuiasodfasodfjcxvkljsdouisaldvjkalieuorals')
            )
          } else {
            $section
          }
        ) }
      }
      |reduce --fold {$key: $doc} {|section, acc|
        $acc|merge $section
      }
    }
  )
  |reduce {|a, b| $a|merge $b}
  print ''
  print ($docindex|transpose|get column0)

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
  |each {|row|
    print -n '.'
    print $"($row.path): ($row.name)"
    let doc = $docindex|get -i ($row.path)

    if ($doc != null) {
      ({
        name: $row.name
        summary: (
          $doc
          |pandoc -f html -t plain --wrap=none
          |lines
          |skip until {|line| $line =~ "^[A-Za-z]"}
          |get 0?
          |default ''
          |split column '.'
          |get column1?.0?
          |default ''
        )
        description: ($doc|html-to-md)
      })
    } else {
      ({})
    }
  }
  |where {|| $in.name? != null }
}

def html-to-md [] {
  pandoc -f html -t gfm --wrap=none --lua-filter $"($env.PKD_PATH)/pandoc-strip-images.lua"
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
  let metadata = index|where {|| $in.slug == $slug}|get 0?

  if ($metadata == null) {
    print $"Couldn't find devdocs with the slug ($slug)"
  } else {
    $env.PKD_CURRENT = {
      about: {
        name: $slug
        text_format: 'markdown'
        generator: 'src:devdocs'
        version: $metadata.version
      },
      doctable: (format (download $slug))
    }
  }

}
