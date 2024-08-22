export use src:devdocs.nu

# Returns a summarized table of all available symbols in the currently selected docfile.
#
# If `name` is passed as an argument, results will be filtered by their name. If `index` is passed as an argument, only the selected result will be returned.
#
# When a single result is found, it'll be presented using `doc present`. If more than one result is found, returned symbols will be summarized using `doc summarize`.
export def main [name?, index?] {
  if (('PKD_CURRENT' in $env) != true) {
    print "No docfile currently selected. Type `doc use <path>` to select a docfile to use."
    return
  }
  if (($name|describe) == 'int') {
    pkd-doctable|get $name|present
  } else if ($name != null) {
    let list = pkd-doctable|find $name -c ['name']

    if ($index != null) {
      $list|get $index|present
    } else {
      $list|present-list
    }
  } else {
    pkd-doctable|present-list
  }
}

export def * [] {
  pkd-doctable|get name
}

def present-list [] {

  if ($in|length) == 1 {
    $in|get 0|present
  } else {
    let docs = $in
    let list = $docs|take 20|summarize-all
    let more = ($docs|length) - 20
    print ($list|table)
    if ($more > 0) {
      print $"Showing 20 symbols out of ($docs|length)"
    }

  }
}

# Sets the current doctable.
#
# `docs` is either a file in the local filesystem or a doctable.
#
# Examples
#
# # Use a docfile from local filesystem
#   ```doc use my-doc-file.pkd```
#
# # Download and use pikadoc CLI reference docs
#   ```doc use (http get 'https://raw.githubusercontent.com/ArseAssassin/pikadoc/master/reference-docs.pkd'|from yaml)```
export def --env use [docs] {
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
  select name? kind? summary?|trim-record-whitespace
}

# Creates a readable summary of all symbols.
#
# `$in` should be a table of pikadoc symbols.
export def summarize-all [] {
  each {|| summarize}
}

alias _save = save

# Saves doctable in the local filesystem.
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

def present [] {
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

  print ($trimmedOutput|table --expand)

  if ((pkd-about).text_format? == 'markdown') {
    $output.description?|glow
  } else {
    print $output.description?
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