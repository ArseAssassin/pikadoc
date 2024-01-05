def html-to-md [] {
  pandoc --from=html --to=gfm-raw_html --wrap=none
}
def get-name [] {
  query web --query '.sig-name.descname'|get 0
}
def get-summary [] {
  query web --query 'dd p'|get 0?|html-to-md
}

def get-description [] {
  query web --query 'dd p' --as-html|str join|html-to-md
}

def get-parameters [headerParams] {
  query web --query 'dl.field-list.simple .simple li' --as-html
  |each {|paramHtml|
    let name = $paramHtml|query web --query 'strong'|get 0?
    let paramDefault = $headerParams|get -i $name
    {
      name: ($paramHtml|query web --query 'strong'|get 0?)
      summary: ($paramHtml|query web --query '*'|get 0?)
      defaultValue: $paramDefault
    }
  }
}

def get-signature [] {
  query web --query 'dt' --as-html|get 0
  |query web --query '.sig-param' --as-html
  |each {|html| {
    ($html|query web --query '.n'|get 0?|default ''): ($html|query web --query '.default_value'|get 0?)
  }}
  |reduce --fold {} {|a, b| $b|merge $a}
}

# Parses a doctable from a HTML documentation page generated using sphinx.
#
# `in` should be a valid sphinx HTML document
#
# Example: http get 'https://flask.palletsprojects.com/en/3.0.x/api/'|doc src:python parse-from-sphinx-html
#
# NOTE: This command parses only a single HTML page. Sphinx documentation typically consists of multiple documents and a single page might not contain all the references you're looking for. To index all symbols, make sure to parse all relevant pages, or use the `singlehtml` builder in Sphinx to produce a single page documentation.
export def parse-from-sphinx-html [] {
  let $doc = $in
  let pyFns = $doc|query web --query '.py.function' --as-html
  let pyClasses = $doc|query web --query '.py.class' --as-html

  print $"Converting (($pyFns|length) + ($pyClasses|length)) symbols, this could take a while"

  let classes = (
    $pyClasses
    |each {|html|
      let name = ($html|get-name)
      let namespace = ($html|query web --query '.sig-prename'|get 0?)
      print -n '.'
      [{
        name: $name,
        namespace: ($namespace|str substring ..-1),
        summary: ($html|get-summary),
        description: ($html|get-description)
        parameters: ($html|query web --query 'dd dl' --as-html|get 0|get-parameters ($html|get-signature))
        kind: 'class'
      }] ++ ($html|query web --query '.py.method' --as-html
        |each {|methodHtml|
          print -n '.'
          {
            name: $"($name).($methodHtml|get-name)"
            namespace: ($namespace|str substring ..-1)
            summary: ($methodHtml|get-summary),
            description: ($methodHtml|get-description)
            parameters: ($methodHtml|get-parameters ($methodHtml|get-signature))
            kind: 'method'
          }}
      ) ++ ($html|query web --query '.py.attribute' --as-html
        |each {|attributeHtml|
          print -n '.'
          {
            name: $"($name).($attributeHtml|get-name)"
            summary: ($attributeHtml|get-summary)
            kind: 'property'
          }}
      )
    }|flatten
  )

  let functions = (
    $pyFns
    |each {|html|
      print -n '.'
      {
        name: ($html|get-name)
        namespace: ($html|query web --query '.sig-prename'|get 0?|str substring ..-1)
        summary: ($html|get-summary)
        parameters: ($html|get-parameters ($html|get-signature))
        description: ($html|get-description)
        kind: 'function'
      }
    }
  )

  $classes|append $functions
}

# Parses a HTML documentation page generated using sphinx and selects it as the current doctable
#
# `url` should be a URL to a sphinx-generated HTML page
#
# Example: doc src:python use "https://flask.palletsprojects.com/en/3.0.x/api/"
#
# NOTE: This parses only a single HTML page. If API documentation is spread over multiple files, see documentation for `parse-from-sphinx-html`
export def-env use [url] {
  print $"Downloading ($url)"
  $env.PKD_CURRENT = (http get $url|parse-from-sphinx-html)
  $env.PKD_ABOUT = {
    name: $url
    text_format: 'markdown'
    generator: 'src:python'
  }
}