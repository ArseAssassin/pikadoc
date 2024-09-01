export def --env main [name] {
  do --env $env.DOC_USE {||
    let docs = http get $"https://raw.githubusercontent.com/ArseAssassin/pkdocs/main/docs/($name).pkd"|from yaml

    {
      about: ($docs|get 0)
      doctable: ($docs|get 1)
    }
  } $"s ($name)"
}

export def index [] {
  http get "https://raw.githubusercontent.com/ArseAssassin/pkdocs/main/docs/index.yml"|select name slug? version?
}