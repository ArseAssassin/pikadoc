export def --env main [name] {
  let docs = http get $"https://raw.githubusercontent.com/ArseAssassin/pkdocs/main/docs/($name).pkd"|from yaml

  do --env $env.DOC_USE {
    about: ($docs|get 0)
    doctable: ($docs|get 1)
  } $"s ($name)"
}

export def index [] {
  http get "https://raw.githubusercontent.com/ArseAssassin/pkdocs/main/docs/index.yml"|select name slug? version?
}