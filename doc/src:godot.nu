def add-text-fields [xml:record] {
  let fields = $in
  let desc = ($xml.content?.content?|default []|parse-body-text)

  $fields|merge {
    summary: ($desc|summarize-description)
    description: ($desc)
  }
}

def parse-signature [] {
  let params = $in

  (
    $params
    |where tag == param
    |each {|param| {
      kind: 'positional'
      name: $param.attributes.name
      type: $param.attributes.type
      default: $param.attributes.default?
    }}
  ) ++ (
    $params
    |where tag == return
    |each {|param| {
      kind: 'return'
      type: $param.attributes.type
    }}
  )
}

def trim-triple-newlines [] {
  let s = $in
  if ("\n\n\n" in $s) {
    $s|str replace "\n\n\n" "\n\n"|trim-triple-newlines
  } else {
    $s
  }
}

def summarize-description [] {
  split row '.'|first
}

def parse-description [] {
  get content?
  |default []
  |where tag == description
  |get 0.content?.content?
  |default []
  |parse-body-text
}

def parse-body-text [] {
  each {
    lines
    |each { str trim }
    |str join "\n\n"
  }
  |str join "\n"
  |trim-triple-newlines
}

# Parses Godot game engine documentation for a doctable. $path should be a directory path to the engine's documentation XML files - for Godot 4 this is `/doc/classes/`.
export def --env use [path:string] {
  let generator_command = $"src:godot ($path|to nuon)"
  do --env $env.DOC_USE {
    cd $path

    {
      about: {
        name: 'godot'
        generator: 'src:godot'
        generator_command: $generator_command
      },
      doctable: (
        ls *.xml
        |each {|file|
          let xml = open $file.name

          def get-content [field:string] {
            $xml.content
            |where tag == $field
            |get 0?.content?
            |default []
          }

          [{
            kind: $xml.tag
            name: $xml.attributes.name
            id: $xml.attributes.name
            summary: (get-content 'brief_description'|get 0?.content?)
            signatures: (
              get-content 'constructors'
              |get content
              |each { parse-signature }
            )
            description: ($xml|parse-description)
            inherits_from: (
              $xml.attributes.inherits?
              |if ($in != null) {
                [$in]
              } else {
                $in
              }
            )
          }] ++ (
            get-content 'methods'
            |each {|method| ({
                kind: 'method'
                name: $"($xml.attributes.name).($method.attributes.name)"
                signatures: [($method.content|parse-signature)]
                belongs_to: $xml.attributes.name
              }|add-text-fields ($method.content|where tag == 'description'|get 0?))
            }
          ) ++ (
            get-content 'operators'
            |each {|method| ({
                kind: 'operator'
                name: $"($xml.attributes.name).($method.attributes.name)"
                signatures: [($method.content|parse-signature)]
                belongs_to: $xml.attributes.name
              }|add-text-fields ($method.content|where tag == 'description'|get 0?))
            }
          ) ++ (
            get-content 'members'
            |each {|member|
              ({
                kind: 'property'
                name: $"($xml.attributes.name).($member.attributes.name)"
                type: $member.attributes.type
                default: $member.attributes.default?
                belongs_to: $xml.attributes.name
              }|add-text-fields $member)
          }) ++ (
            get-content 'constants'
            |each {|constant|
              ({
                kind: (if ($constant.attributes.enum?) != null {
                  'enum'
                } else {
                  'constant'
                })
                name: $"($xml.attributes.name).($constant.attributes.enum?|if ($in != null) { $in + '.' })($constant.attributes.name)"
                value: $constant.attributes.value?
                belongs_to: $xml.attributes.name
              }|add-text-fields $constant)
          }) ++ (
            get-content 'signals'
            |each {|signal|
              ({
                kind: 'signal'
                name: $"($xml.attributes.name).($signal.attributes.name)"
                value: $signal.attributes.value?
                signatures: [($signal.content|parse-signature)]
                belongs_to: $xml.attributes.name
              }|add-text-fields ($signal.content|where tag == 'description'|get 0?))
          })
        }
        |flatten
      )
    }
  } $generator_command
}