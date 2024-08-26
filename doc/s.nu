export def --env main [name] {
  let docs = http get $"https://raw.githubusercontent.com/ArseAssassin/pkdocs/main/docs/($name).pkd"|from yaml
  $env.PKD_CURRENT = {
    about: ($docs|get 0)
    doctable: ($docs|get 1)
  }
}

export def index [] {
  http get "https://raw.githubusercontent.com/ArseAssassin/pkdocs/main/docs/index.yml"|select name slug? version?
}