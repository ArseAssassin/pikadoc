export def markdown-to-summary [] {
  pandoc -f gfm -t html --wrap=none
  |hxnormalize -x
  |hxunent -b
  |xmlstarlet select -t --value-of '//p[contains(., '.')][1]'
  |lines
  |each {|| str trim}
  |str join ' '
  |split row '.'
  |get 0
  |str trim
}

export def 'profile file' [] {
  $"($env.PKD_CONFIG_HOME)/profile.yml"
}

export def profile [] {
  if (not ((profile file)|path exists)) {
    {}
  } else {
    open (profile file)
  }
}

export def 'profile get' [name:string, defaultValue:any] {
  profile|get -i $name|default $defaultValue
}

export def 'profile set' [name:string, value:any] {
  profile|merge {$name: $value}|to yaml|save -f (profile file)
}

export def 'doctable id' [] {
  get about|$"($in.name)~($in.version)"
}