use helpers.nu

def format-name [] {
  str replace -a "\n" ""
}

def collect-links [name:string] {
  xmlstarlet sel -t -v $"//a/@href"
  |lines
  |where {not ($in|str starts-with http)}
  |uniq
  |each {
    if ($in|str starts-with '#') {
      $name + $in
    } else {
      $in
    }
  }
}

def subheader-query [name] {
  $"//*[@id=\"(($name))\" or @name=\"(($name))\"][1]"
}

export def --env use [path:string, options:record={}] {
  do --env $env.DOC_USE {
    cd $path

    let found = ls **/*.html
    print $"Found ($found|length) files, processing..."
    let files = (
      $found
      |each {|file|
        print -n '.'
        {
          name: $file.name
          html: (
            open $file.name
            |do $env.PKD_CONFIG.tidy_command
            |complete
            |get stdout
            |str replace ' xmlns="http://www.w3.org/1999/xhtml"' ""
            |hxunent -b
            |if ($options.language? != null) {
              xmlstarlet ed --update '//pre/@class' --value $options.language
            } else {
              $in
            }
            |if ($options.stripElements? != null) {
              xmlstarlet ed -P -d ($options.stripElements|default '')
            } else {
              $in
            }
            # glow has a problem rendering blockquoted code blocks
            |xmlstarlet ed -r '//blockquote[pre]' -v 'div'
          )
        }
    }
    )
    let links = (
      $files
      |each {|file| get html|collect-links $file.name }
      |flatten
      |uniq
    )
    print ''
    print $"Found ($links|length) sections, processing..."
    {
      about: {
        name: $path
        generator: 'src:html'
        text_format: 'markdown'
      }
      doctable: (
        $files
        |each {|page|
          print -n .
          let html = $page.html
          let title = ($html|xmlstarlet sel -t -v "//title")
          let local_links = (
            $links
            |where { $in|str starts-with $page.name }
          )
          let desc = ($html|pandoc -f html -t gfm-raw_html-tex_math_dollars)
          let sectioned_doc = (
            $local_links
            |reduce --fold $html {|section_name, xhtml|
              let local_section_name = $section_name|parse $"($page.name)#{name}"|get 0?.name?

              if ($local_section_name == null) {
                $xhtml
              } else {
                $xhtml
                |xmlstarlet ed -i (subheader-query $local_section_name) -t elem -n 'pre' -v $"PIKADOC_PAGE_BREAK ::: `($local_section_name)` :::"
              }
            }
            |pandoc -f html -t gfm-raw_html-tex_math_dollars
          )

          [{
            name: ($title|format-name)
            summary: ($desc|helpers markdown-to-summary)
            description: $desc
            kind: 'page'
            id: $page.name
            ns: $page.name
          }] ++ (
            $sectioned_doc
            |split row '    PIKADOC_PAGE_BREAK ::: '
            |each {parse "`{name}` :::{rest}"}
            |filter {$in != []}
            |each {|section_parts|
              print -n .
              let name = $section_parts.0.name
              let id = $"($page.name)#($name)"
              {
                name: (
                  $html
                  |xmlstarlet sel -t -v (subheader-query $name)
                  |format-name
                  |if ($in == '') {
                    $section_parts.0.rest
                    |lines
                    |where {($in|str trim) != ''}
                    |get 0?
                    |default ''
                    |pandoc -f gfm -t plain
                  } else {
                    $in
                  }
                )
                id: $id
                kind: 'section'
                description: $section_parts.0.rest
                belongs_to: $page.name
                ns: $page.name
              }
            }
            |where {
              ($in.description?|default ''|str trim) != ''
            }
            |each { merge {
              summary: ($in.description|helpers markdown-to-summary)
            }}
          )
        }
        |flatten
      )
    }
  }
}