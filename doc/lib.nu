use helpers.nu
use pkd.nu

# Allows you to query any doctable in the current library. `$doctable` is the name or index of the doctable. `$query` works similarly as when calling `doc`.
export def main [doctable, query?] {
  do {
    pkd use (select $doctable)
    do $env.DOC $query
  }
}

def lib [] {
  $env.pkd.lib
}

# Lists all doctables in the current library
export def index [] {
  lib|each { helpers doctable id }
}

# Adds a doctable to the current library. `$mount` is a closure used to mount the correct doctable. If `$mount` is null, currently mounted doctable is used instead.
#
# ### Examples:
# ```nu
# doc lib add { doc s use html }
# ```
export def --env add [mount?:closure] {
  let doctable = (
    if ($mount != null) {
      do {
        do --env $mount
        $env.PKD_CURRENT
      }
    } else {
      $env.PKD_CURRENT
    }
  )
  $env.pkd.lib = (
    lib
    |append $doctable
    |uniq
  )

  index
}

def --env set [doctables:list<any>] {
  $env.pkd.lib = $doctables
}

def select [doctable] {
  if (($doctable|describe) == 'string') {
    let query = $doctable|str downcase
    (
      lib
      |where {
        $query in ($in.about.name|str downcase)
      }
      |first
    )
  } else {
    lib|get $doctable
  }
}

# Mounts `$doctable` as the current doctable. If `$doctable` is a string, it's used to match the name of the selected doctable. If `$doctable` is an int, it's matched with the `#` of the doctable, as returned by `doc lib index`.
#
# ### Examples:
# ```nu
# # Mount the first doctable in the current library
# doc lib use 0
#
# # Mount doctable named html in the current library
# doc lib use html
# ```
export def --env use [doctable] {
  pkd use (select $doctable)
}

# Removes `$doctable` from the current library. If `$doctable` is a string, it's used to match the name of the selected doctable. If `$doctable` is an int, it's matched with the `#` of the doctable, as returned by `doc lib index`.
#
# ### Examples:
# ```nu
# # Removes doctable #0 from the current library
# doc lib remove 0
#
# # Removes doctable html from the current library
# doc lib remove 'html'
# ```
export def --env remove [doctable] {
  let selected = select $doctable
  $env.pkd.lib = (
    lib
    |where {$in != $selected}
  )

  index
}

# Clears all doctables from the current library
export def --env clear [] {
  $env.pkd.lib = []
  index
}

# Run `$query` against every doctable in the library. Sorts results by `relevance`. For every result, prefix `ns` with the source doctable name.
#
# ### Examples:
# ```nu
# # Search all doctables in the current library for 'add'
# doc lib query {doc 'module'}
# ```
export def query [
  query:closure # query to run for each doctable
  ] {
  lib
  |each {|doctable|
    do {
      pkd use $doctable

      do $query
      |each {|row| $row|merge {
        ns: $"\(($doctable.about.name)\) ($row.ns?)"
      } }
    }
  }
  |flatten
  |sort-by relevance
}

alias _save = save

# Saves current library into `$library_file` with all doctables in the current library. If `$doc_path` is passed, it's joined to `$library_file` to get the directory where pkd files should be saved.
export def save [library_file:string, doc_path?:string=''] {
  let output = $library_file|path expand
  cd ($library_file|path dirname)

  let docs = (
    lib
    |each {|doctable|
      do {
        pkd use $doctable
        let file_path = (
          $doc_path
          |path join (($doctable|helpers doctable id) + '.pkd')
        )

        pkd save $file_path

        $file_path
      }
    }
  )

  $docs
  |each {|file| {
    path: ($file)
  }}
  |to yaml
  |do {$"# This is a pikadoc library index file. Check paths listed below for the actual documentation files:\n($in)"}
  |_save -f $output

  (ls $output) ++ (
    $docs
    |each { ls ($in|path expand)|first }
  )
}

# Loads a saved `$library_file` and replaces the current library with it. Assumes that all doctables are stored in relative path to `$library_file`.
export def --env load [library_file:string] {
  cd ($library_file|path dirname)

  set (
    open ($library_file|path basename)
    |from yaml
    |each {|doctable|
      do {
        pkd use $doctable.path
        pkd full
      }
    }
  )

  pkd use (lib|first)
}