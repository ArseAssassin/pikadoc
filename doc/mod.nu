# Returns a summarized table of all available symbols in the currently selected docfile.
#
# If (name) is passed as an argument, results will be filtered by their name. If (index) is passed as an argument, only the selected result will be returned.
#
# When a single result is found, it'll be presented using `doc present`. If more than one result is found, returned symbols will be summarized using `doc summarize`.
export def main [name?, index?] {
  if (('PKD_CURRENT' in $env) != true) {
    print "No docfile currently selected. Type `doc use <path>` to select a docfile to use."
    return
  }
  if (($name|describe) == 'int') {
    $env.PKD_CURRENT|get $name|present
  } else if ($name != null) {
    let list = $env.PKD_CURRENT|search $name

    if ($index != null) {
      $list|get $index|present
    } else {
      $list|present-list
    }
  } else {
    $env.PKD_CURRENT|present-list
  }
}

def present-list [] {
  if ($in|length) == 1 {
    $in|get 0|present
  } else {
    $in|summarize-all
  }
}

# Sets the current doctable.
#
# `docs` is either a file in the local filesystem or a doctable.
#
# Examples
# # Use a docfile from local filesystem
#   doc use my-doc-file.pkd
#
# # Download and use pikadoc CLI reference docs
#   doc use (http get 'https://raw.githubusercontent.com/ArseAssassin/pikadoc/master/reference-docs.pkd'|from yaml)
export def-env use [docs] {
  let type = $docs|describe
  if ($type == 'string') {
    $env.PKD_CURRENT = (open $docs|from yaml)
  } else {
    $env.PKD_CURRENT = $docs
  }
}

# Returns the currently selected doctable without applying any formatting.
export def-env all [] {
  $env.PKD_CURRENT
}

def search [name] {
  find $name -c ["name"]
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
# `in` is a valid doctable
# `filepath` is a path to use for saving the file
export def save [filepath] {
  to yaml|_save -f $filepath
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

def html-to-md [] {
  pandoc --from=html --to=gfm-raw_html
}

def present [] {
  trim-record-whitespace
  |maybe-update description {|| mdcat }
  |maybe-update type {|| str join ' -> '}
  |maybe-update parameters {|| each {|| trim-record-whitespace }}
}

def maybe-update [name, value] {
  if ($in|get -i $name) != null {
    update $name $value
  } else {
    $in
  }
}
