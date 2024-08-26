def normalize-html [] {
  hxnormalize -x
}

export def download [name] {
  let url = $"https://downloads.devdocs.io/($name).tar.gz"
  print $"Downloading ($url)"
  let it = http get $url
  print "Download finished"
  $it
}

def is-inline-section [] {
  ($in
  |query web --query 'address, article, aside, blockquote, canvas, dd, div, dl, dt, fieldset, fieldset, figcaption, figure, footer, form, h1, h2, h3, h4, h5,h6, header, hr, li, main, nav, noscript, ol, p, pre, section, table, tfoot, ul, video'
  |length) <= 1
}

def merge-all [] {
  reduce --fold {} {|a, b|
    $a|merge $b
  }
}

export def generate-page-index [key, doc, options:record={}] {
  let preprocessedDoc = if ($options.stripNodes? != null) {
    $doc
    |normalize-html
    |hxremove $options.stripNodes
  } else {
    $doc
  }

  let htmlSections = (
    $preprocessedDoc
    |query web --query '.section, dl' --as-html
    |each {|section|
      let id = $section|query web --query '[id]' -a id|get 0?
      if ($id != null) {
        { $"($key)#($id)": $section }
      } else {
        {}
      }
    }
    |merge-all
  )

  $preprocessedDoc
  |query web --query '[id]' --as-html
  |each {|section|
    let sectionId = $section|normalize-html|query web --query '[id]' -a id|get 0
    { $"($key)#($sectionId)": (
      if ($section|is-inline-section) {
        let subdoc = $preprocessedDoc|str substring ($preprocessedDoc|str index-of $section)..

        print $"inline ($sectionId)"

        # try {
          $subdoc|str substring ..(
            $subdoc|str index-of ($subdoc|query web --query $"[id]:not\(.method-source-code\)" --as-html|get 0?|default 'dasofuisdaofuiasodfasodfjcxvkljsdouisaldvjkalieuorals')
          )
        # } catch {
        #   print $"Error while processing section id ($sectionId)"
        #   $subdoc
        # }

      } else {
        $section
      }
    ) }
  }
  |merge-all
  |merge $htmlSections
  |merge {$key: $preprocessedDoc}
}

export def generate-doc-index [options:record] {
  tar -zx ./db.json -O
  |complete
  |get stdout
  |from json
  |items {|key, doc|
    print -n .

    generate-page-index $key $doc $options
  }
  |reduce {|a, b| $a|merge $b}
}

def format [archive:binary, options:record] {
  print "Extracting data"
  let htmldocs = $archive|tar -zx ./db.json -O|complete|get stdout|from json
  let docindex = $archive|generate-doc-index $options
  print ''

  let copyright = $docindex.index|query web --query '._attribution' --as-html|last|pandoc -f html -t plain

  let entries = (
    $archive
    |tar -zx ./index.json -O
    |complete
    |get stdout
    |from json
    |get entries
  )

  print $"Converting ($entries|length) HTML pages"

  let doctable = (
    $entries
    |each {|row|
      print -n .
      let doc = (
        $docindex
        |get -i ($row.path)
        |default (
          $docindex
          |get -i ($row.path|parse '{path}#{_}'|get 0?.path?|default '')
        )
      )

      if ($doc != null) {
        ({
          name: $row.name
          summary: (
            $doc
            |query web --query 'p:not([class])'
            |get 0?
            |default []
            |str join ''
            |split row -r '\.\s'
            |get 0?
            |default ''
            |str trim
            |str replace -r '\.$' ''
          )
          belongs_to: (if ($row.path|str contains '#') {
            let parentDoc = (
              $row.path
              |split row '#'
              |get 0
            )

            $entries
            |where {|| $in.path == $parentDoc}
            |get 0?.name?
          })
          description: ($doc|html-to-md)
        })
      } else {
        ({})
      }
    }
    |where {|it| $it.name? != null and $it.description? != null and ($it.description|str trim) != ''}
    |each {|it|
      if ($it.belongs_to? == null) {
        $it|reject 'belongs_to'
      } else {
        $it
      }
    }
  )

  { doctable: $doctable, copyright: $copyright }
}

def html-to-md [] {
  pandoc -f html -t gfm-raw_html --wrap=none --lua-filter $"($env.PKD_PATH)/pandoc-strip-images.lua"
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
export def --env use [slug, options={}] {
  let metadata = index|where {|| $in.slug == $slug}|get 0?

  if ($metadata == null) {
    print $"Couldn't find devdocs with the slug ($slug)"
  } else {
    let docs = (format (download $slug) $options)
    $env.PKD_CURRENT = {
      about: {
        name: $metadata.name
        slug: $slug
        text_format: 'markdown'
        generator: 'src:devdocs'
        version: $metadata.version
        copyright: $docs.copyright
        homepage: $metadata.links_home
      },
      doctable: $docs.doctable
    }
  }

}
