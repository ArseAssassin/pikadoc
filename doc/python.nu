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

export def parse-from-sphinx-html [] {
  let $doc = $in
  let classes = (
    $doc|query web --query '.py.class' --as-html
    |each {|html|
      let name = ($html|get-name)
      let namespace = ($html|query web --query '.sig-prename'|get 0?)
      [{
        name: $name,
        namespace: ($namespace|str substring ..-1),
        summary: ($html|get-summary),
        description: ($html|get-description)
        parameters: ($html|query web --query 'dd dl' --as-html|get 0|get-parameters ($html|get-signature))
        kind: 'class'
      }] ++ ($html|query web --query '.py.method' --as-html
        |each {|methodHtml| {
          name: $"($name).($methodHtml|get-name)"
          namespace: ($namespace|str substring ..-1)
          summary: ($methodHtml|get-summary),
          description: ($methodHtml|get-description)
          parameters: ($methodHtml|get-parameters ($methodHtml|get-signature))
          kind: 'method'
        }}
      ) ++ ($html|query web --query '.py.attribute' --as-html
        |each {|attributeHtml| {
          name: $"($name).($attributeHtml|get-name)"
          summary: ($attributeHtml|get-summary)
          kind: 'property'
        }}
      )
    }|flatten
  )
  let functions = (
    $doc|query web --query '.py.function' --as-html
    |each {|html|
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

  [$classes $functions]|flatten
}