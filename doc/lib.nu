use helpers.nu

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
# ```nushell
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

def select [doctable] {
  if (($doctable|describe) == 'string') {
    let query = $doctable|str downcase
    (
      lib
      |where {
        (($in.about.name|str downcase) == $query) or (
          $in|helpers doctable id|str downcase) == $query
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
# ```nushell
# # Mount the first doctable in the current library
# doc lib use 0
#
# # Mount doctable named html in the current library
# doc lib use html
# ```
export def --env use [doctable] {
  do --env $env.DOC_USE (select $doctable)
}

# Removes `$doctable` from the current library. If `$doctable` is a string, it's used to match the name of the selected doctable. If `$doctable` is an int, it's matched with the `#` of the doctable, as returned by `doc lib index`.
#
# ### Examples:
# ```nushell
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


# Run `$query` against every doctable in the library. Sorts results by `relevance`. For every result, prefix `ns` with the source doctable name.
#
# ### Examples:
# ```nushell
# # Search all doctables in the current library for 'add'
# doc lib query {doc add}
# ```
export def query [query:closure] {
  lib
  |each {|doctable|
    do {
      do --env $env.DOC_USE $doctable

      do $query
      |each {|row| $row|merge {
        ns: $"\(($doctable.about.name)\) ($row.ns?)"
      } }
    }
  }
  |flatten
  |sort-by relevance
}