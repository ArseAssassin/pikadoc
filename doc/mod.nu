export use s.nu
export use src:devdocs.nu
export use src:man.nu
export use src:sqlite.nu
export use src:python.nu
export use src:openapi.nu
export use src:javascript.nu
export use src:nushell.nu
export use src:github.nu

# Returns a summarized table of all available symbols in the currently selected docfile.
#
# If `name` is passed as an argument, results will be filtered by their name. If `index` is passed as an argument, only the selected result will be returned.
#
# When only a single result is found, it'll be presented as whole. If more than one result is found, returned results will be shown in a summarized table.
export def --env main [name?] {
  if (('PKD_CURRENT' in $env) != true) {
    print "No docfile currently selected. Type `doc use <path>` to select a docfile to use."
    return
  }
  if (($name|describe) == 'int') {
    pkd-doctable|get $name|present
  } else if ($name != null) {
    let query = ($name|str downcase)
    let search = (
      pkd-doctable
      |add-doc-ids
      |find $name -c ['name', 'summary']
    )

    if (($search|length) == 1) {
      $search|get 0|present
    } else {
      let list = (
        $search
        |insert dist {|row| (
          (($row.name|ansi strip|str downcase|str index-of $query|if ($in == -1) { 100 } else { $in }) * 100) +
          (($row.summary|ansi strip|str downcase|find $query|length) * -10) +
          ($row.description|ansi strip|str downcase|find $query|length) * -1
        )}
        |sort-by dist
        |reject dist
      )

      $list|summarize-all|present-list
    }
  } else {
    pkd-doctable|add-doc-ids|summarize-all|present-list
  }
}


# Searches the descriptions of all symbols in the current doctable for `query`. System grep is used for matching output.
export def --env search [query:string] {
  if (('PKD_CURRENT' in $env) != true) {
    print "No docfile currently selected. Type `doc use <path>` to select a docfile to use."
    return
  }

  pkd-doctable
  |add-doc-ids
  |find ($query) -c ['description']
  |insert ranking {|row| (
    $row.description
    |ansi strip
    |grep -F -i -o $query
    |lines
    |length
  ) * -1}
  |sort-by ranking
  |insert results {|row|
    $row.description
    |grep -F -i $query -A0 -B0 --group-separator='...' -m 5
  }
  |select '#' name kind? results
  |present-list
}

def add-doc-ids [] {
  zip 0..|each {|vals| {'#': $vals.1}|merge $vals.0}
}

export def --env * [] {
  pkd-doctable|paginate 100000000 true
}

def result-lines [] {
  20
}

def --env present-list [] {
  paginate (result-lines) true
}

def --env paginate [resultLines:int, newResults=false] {
  let docs = $in

  if ($newResults) {
    $env.PKD_CURSOR = 0
    $env.PKD_RESULTS = $docs
  } else {
    $env.PKD_CURSOR += $resultLines
  }

  let list = $docs|skip $env.PKD_CURSOR|take $resultLines

  print ($list|table -i false)

  if (($env.PKD_CURSOR + $resultLines) < ($docs|length)) {
    print $"Showing ($env.PKD_CURSOR + $resultLines) results out of ($docs|length), type `doc more` for more results"
  } else {
    $env.PKD_CURSOR = 0
  }
}

# Shows more results from the last search. If `index` is passed as an argument, the given result will be selected from the last result set and presented as a whole.
#
# Examples
#
# # Show more results from the last search
#   ```doc more```
#
# # Show result number 8
#   ```doc more 8```
export def --env more [index?:int] {
  if ($index != null) {
    $env.PKD_RESULTS|get ($index)|present
  } else {
    $env.PKD_RESULTS|paginate (result-lines)
  }
}

# Sets the current doctable.
#
# `docs` is either a file in the local filesystem or a pikadoc table.
#
# Examples
#
# # Use a docfile from local filesystem
#   ```doc use my-doc-file.pkd```
#
# # Use a docfile downloaded from a server
#   ```doc use (http get 'https://raw.githubusercontent.com/ArseAssassin/pikadoc/master/reference-docs.pkd'|from yaml)```
export def --env use [docs, command?:string] {
  let type = $docs|describe
  if ($type == 'string') {
    let file = (open $docs|from yaml)
    $env.PKD_CURRENT = {
      about: $file.0
      doctable: $file.1
    }
  } else {
    $env.PKD_CURRENT = $docs
  }

  if ($command != null) {
    $command
  } else {
    $"use ($docs)"
  }
  |add-to-history
}

export def pkd-about [] {
  $env.PKD_CURRENT|get about
}

export def pkd-doctable [] {
  $env.PKD_CURRENT|get doctable
}

def show [] {
  less -S --chop-long-lines
}

def "from pkd" [] {
  from yaml
}

# Creates a readable summary of a single symbol.
#
# `$in` should be a pikadoc symbol.
export def summarize [] {
  select '#'? name? kind? summary?|trim-record-whitespace
}

# Creates a readable summary of all symbols.
#
# `$in` should be a table of pikadoc symbols.
export def summarize-all [] {
  each {|| summarize}
}

alias _save = save

# Saves doctable in the filesystem.
#
# `filepath` is a path to use for saving the file
export def save [filepath: string] {
  ['---', (pkd-about|to yaml), '---', (pkd-doctable|to yaml)]|str join "\n"|_save -f $filepath
}

def map-record-values [block: closure] {
  items $block|reduce --fold {} {|a, b| $b|merge $a}
}

def trim-record-whitespace [] {
  map-record-values {|key, value| {
    $key: (if (($value|describe) == 'string') {
      $value|str trim
    } else {
      $value
    })
  }}
}

export def present [] {
  let output = $in
    |trim-record-whitespace
    |maybe-update type {|| str join ' -> '}
    |maybe-update parameters {|| each {|| trim-record-whitespace }}

  let trimmedOutput = if ($output.summary? == '' or ($output.summary?|default ''|str trim) ==
      ($output.description?|default ''|str trim)) {
    $output|reject summary? description?
  } else {
    $output|reject description?
  }

  let meta = $trimmedOutput|table --expand

  if ((pkd-about).text_format? == 'markdown') {
    let body = $output.description?|glow -s auto|complete|get stdout

    $"($meta)\n\n($body)"
  } else {
    $"($meta)\n\n($output.description?)"
  }

}

def maybe-update [name, value] {
  if ($in|get -i $name) != null {
    update $name $value
  } else {
    $in
  }
}

# Returns current pikadoc version
export def version [] {
  $env.PKD_VERSION
}

def history-file [] {
  $"($env.PKD_CONFIG_HOME)/history.yml"
}

def _history [] {
  if (not (history-file|path exists)) {
    []|to yaml|_save (history-file)
  }

  open (history-file)
}

# Returns a list of the last 50 doctables selected with `doc use`
export def history [] {
  _history
  |take 50
  |each {|| $"doc ($in)"}
}

def add-to-history [] {
  let cmd = $in
  _history
  |collect { ||
    prepend $cmd
    |uniq
    |to yaml
    |_save -f (history-file)
  }

}