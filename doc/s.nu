# Mounts doctable with `name` for use from the pikadoc central repository.
# To get a list of available doctables, see `doc s index`.
#
# ### Example:
#     ```> doc s python~3.13```
#
export def --env use [
  path:string # path to the file to use, including the version number
  ] {
  do --env $env.DOC_USE {||
    let matches = find-doc $path
    if (($matches|length) != 1) {
      print (
        $matches
        |select name path version? generator
      )
      print $"Found ($matches|length) results when searching for `($path)`"
      print $"Type `doc s $path` to specify results"
      return
    } else {
      let docs = http get ($matches.0.repoUrl)|from yaml

      {
        about: ($docs|get 0)
        doctable: ($docs|get 1)
      }
    }

  } $"s ($path|str downcase)"
}

# Returns a list of doctables available in the pikadoc central repository.
# See `doc s use` for more information.
export def --env index [] {
  index full
  |insert id {|row| $row.path|path basename|str substring ..-4}
  |select name id version? generator
}

export def --env 'index full' [] {
  if ($env.PKD_REPO_INDEX? == null) {
    $env.PKD_REPO_INDEX = (http get "https://raw.githubusercontent.com/ArseAssassin/pkdocs/main/docs/index.yml")
  }

  $env.PKD_REPO_INDEX
}

def find-doc [path:string] {
  let docs = (
    index full
    |find -c ['path'] $path
    |each {
      insert repoUrl {|| $"https://raw.githubusercontent.com/ArseAssassin/pkdocs/main/docs/($in.path|ansi strip)"}
    }
  )

  let exactMatches = $docs|where {$in.path|ansi strip|str ends-with $"/($path).pkd"}
  if ($exactMatches != []) {
    $exactMatches
  } else {
    $docs
  }
}