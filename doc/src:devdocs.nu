def normalize-html [] {
  hxnormalize -x|hxunent -b
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

export def generate-page-index [docPath:string, doc:string, sections:list, options:record={}] {
  let preprocessedDoc = (
    $doc
    |normalize-html
    |xmlstarlet ed -d $"//img|//svg|//button|//video|//iframe|//area|//audio|//map|//track|//embed|//object|//picture|//portal|//source|($options.stripElements?|default '*[false()]')"
  )
  let sectionedMarkdown = (
    $sections
    |reduce --fold $preprocessedDoc {|sectionName, xml|
      let localSectionName = $sectionName|parse $"($docPath)#{name}"|get 0.name
      $xml|xmlstarlet ed -i $"//*[@id=\"(($localSectionName))\"][1]" -t elem -n 'pre' -v $"PIKADOC_PAGE_BREAK ::: `($localSectionName)` :::"
    }
    |html-to-md
  )

  $"    PIKADOC_PAGE_BREAK ::: `` :::\n\n($sectionedMarkdown)"
  |split row '    PIKADOC_PAGE_BREAK ::: '
  |where {|| $in != ''}
  |each {|section|
    let sectionParts = $section|parse "`{name}` :::{rest}"
    { $"($docPath)#($sectionParts.0.name)": $sectionParts.0.rest }
  }
  |merge-all
  |merge { $docPath: ($preprocessedDoc|html-to-md) }
}

export def generate-doc-index [entries:table, options:record] {
  let db = (
    tar -zx ./db.json -O
    |complete
    |get stdout
    |from json
  )

  $db
  |items {|key, doc|
    print -n .

    generate-page-index $key $doc (
      $entries
      |each {|| get path }
      |where {|| ($in|str starts-with $"($key)#") }
    ) $options
  }
  |merge-all
  |merge { PIKADOC_COPYRIGHT: (
    $db.index
    |query web --query '._attribution' --as-html
    |last
    |pandoc -f html -t plain
  ) }
}

def format [archive:binary, options:record] {
  print "Extracting data"

  let entries = (
    $archive
    |tar -zx ./index.json -O
    |complete
    |get stdout
    |from json
    |get entries
  )
  let docindex = $archive|generate-doc-index $entries $options
  print ''

  let copyright = $docindex.PIKADOC_COPYRIGHT

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
            |pandoc -fgfm -t html-tex_math_dollars --wrap=none
            |query web --query p
            |each {||
              str join ''
              |str replace -a "\n" ' '
              |str trim
              |parse --regex '(.+?[A-Za-z0-9])\.($|\s)'
            }
            |flatten
            |get 0?.capture0?
            |default null
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
          description: $doc
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
  pandoc -f html -t gfm-raw_html-tex_math_dollars --wrap=none --lua-filter $"($env.PKD_PATH)/pandoc-strip-images.lua"
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
