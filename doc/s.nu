# Mounts doctable with `name` for use from the pikadoc central repository.
# To get a list of available doctables, see `doc s index`.
#
# ### Example:
#     ```> doc s use python~3.13```
#
export def --env main [
  slug:string # url slug of the file to use, including the version number
  ] {
  do --env $env.DOC_USE {||
    let docs = http get $"https://raw.githubusercontent.com/ArseAssassin/pkdocs/main/docs/($slug|str downcase).pkd"|from yaml

    {
      about: ($docs|get 0)
      doctable: ($docs|get 1)
    }
  } $"s ($slug|str downcase)"
}

# Returns a list of doctables available in the pikadoc central repository.
# See `doc s` for more information.
export def index [] {
  http get "https://raw.githubusercontent.com/ArseAssassin/pkdocs/main/docs/index.yml"|select name slug? version?
}