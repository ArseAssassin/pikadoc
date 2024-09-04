def normalize-html [] {
  hxnormalize -x|hxunent -b
}

def download [name] {
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

def generate-page-index [docPath:string, doc:string, sections:list, options:record={}] {
  let preprocessedDoc = (
    $doc
    |normalize-html
    # Remove multimedia elements as they can't be supported in text output.
    # Remove linebreaks in tables as they can't be represented in Markdown.
    |xmlstarlet ed -P -d $"//img|//svg|//button|//video|//iframe|//area|//audio|//map|//track|//embed|//object|//picture|//portal|//source|//table//br|($options.stripElements?|default '*[false()]')"
  )
  let sectionedMarkdown = (
    $sections
    |reduce --fold $preprocessedDoc {|sectionName, xml|
      let localSectionName = $sectionName|parse $"($docPath)#{name}"|get 0.name

      # insert section breaks into xhtml
      $xml|xmlstarlet ed -i $"//*[@id=\"(($localSectionName))\"][1]" -t elem -n 'pre' -v $"PIKADOC_PAGE_BREAK ::: `($localSectionName)` :::"
    }
    # pandoc handles `dl` elements strangely, inserting unnecessary whitespace
    # and deleting elements, transform them into divs to work around this
    |xmlstarlet ed -r '//dl' -v 'div'
    |html-to-md
  )

  # parse xhtml into named sections
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

def generate-doc-index [entries:table, options:record] {
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
          id: $row.path
          summary: (
            $doc
            |pandoc -fgfm -t html-tex_math_dollars --wrap=none
            |query web --query p
            |each {||
              str join ''
              |str replace -a "\n" ' '
              |str trim
              |parse --regex '(.+?[A-Za-z0-9\)\]])\.($|\s)'
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
          description: ($doc|str trim)
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
  # pandoc inserts an empty comment between two `dl` elements when rendering
  # to markdown - as a workaround, replace such paragraphs with two newlines
  |str replace "\n\n&nbsp;\n\n" "\n\n"
}

# Retrieves a list of available documentation files from devdocs.io
# and returns them as a table
export def index [] {
  http get https://devdocs.io/docs.json
  |select name slug version? links?.home?
}

# Downloads and attempts to parse a file downloaded from devdocs.io
# into a doctable. This can be a slow process, so it's best to
# use `doc s` over this when possible. If `options` is passed,
# `$options.stripElements` should be an XPath selector that's used
# to strip unnecessary elements from the HTML input.
export def --env use [
  slug:string, # url slug of the documentation to use
  options={}   # options for parsing
] {
  let metadata = index|where {|| $in.slug == $slug}|get 0?
  let generatorCommand = $"src:devdocs use ($slug) (if ($options != {}) { $options } else { null })"

  if ($metadata == null) {
    print $"Couldn't find devdocs with the slug ($slug)"
  } else {
    do --env $env.DOC_USE {||
      let docs = (format (download $slug) $options)
      {
        about: {
          name: $metadata.name
          slug: $slug
          text_format: 'markdown'
          generator: 'src:devdocs'
          generator_command: 'src:devdocs'
          version: $metadata.version
          copyright: $docs.copyright
          homepage: $metadata.links_home
        },
        doctable: $docs.doctable
      }
    }  $generatorCommand
  }

}
