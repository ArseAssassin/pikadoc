def peek [] {
  let it = $in
  print $it
  $it
}

def normalize-type [doc] {
  if ($doc.$ref? != null) {
    $doc.$ref
    |default ''
    |parse "#/definitions/{type}"
    |get 0?
    |if ($in.type? != null) {
      $"definitions.($in.type)"
    }
  } else if ($doc.schema? != null) {
    normalize-type $doc.schema
  } else if ($doc.type? != null) {
    $doc.type
  }
}
 def normalize-subtypes [doc] {
  if ($doc.enum? != null) {
    $doc.enum|each {|| to json}
  } else if ($doc.items? != null) {
    [(normalize-type $doc.items)]
  } else if ($doc.schema? != null) {
    (normalize-subtypes $doc.schema)
  }
}

def parse-from-path [method, path, it] {
  if ($it != null) {{
    name: $"($method) ($path)"
    summary: ($it.summary?|default $it.description?)
    description: $it.description?
    parameters: ($it.parameters?|default []|each {|param| {
      name: $param.name?
      summary: ($param.summary?|default $param.description?)
      description: $param.description?
      optional: ($param.required? == false)
      type: (normalize-type $param)
      subtypes: (normalize-subtypes $param)
    }})
    accepts: ($it.consumes?|default [])
    contentTypes: ($it.produces?|default [])
    responses: ($it.responses?|default []|items {|status, response|
      {
        status: $status
        summary: $response.description?
        type: (normalize-type $response)
        subtypes: (normalize-subtypes $response)
      }
    })
    kind: 'rest-endpoint'
  }} else {null}
}

# Returns documentation for a REST endpoint defined in a .json/.yaml file.
#
# `$in` is a record parsed from a valid Swagger .json/.yaml file
#
# Example: http get 'https://petstore.swagger.io/v2/swagger.json'|doc src:openapi parse-from-swagger
export def parse-from-swagger [] {
  let $doc = $in

  ($doc|get paths|items {|path, def|
    [
      (parse-from-path GET $path $def.get?)
      (parse-from-path POST $path $def.post?)
    ]|filter {|| $in != null}
  }|flatten) ++ (
    $doc
    |get definitions
    |items {|name, def|
      {
        name: $name,
        kind: 'schema'
        namespace: definitions
        parameters: ($def.properties|items {|name, param| {
          name: $name,
          type: (normalize-type $param)
          subtypes: (normalize-subtypes $param)
          examples: ($param.example?|if ($in != null) {
            [$in]
          })
        }})
      }
    }
  )
}

export def-env use [url] {
  $env.PKD_CURRENT = (http get $url|parse-from-swagger)
  $env.PKD_ABOUT = {
    name: $url
    text_format: 'gfm'
    generator: 'src:openapi'
  }
}