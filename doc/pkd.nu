use cache.nu

alias _save = save

# Saves doctable in the filesystem.
export def save [
  filepath: string        # path to use for saving the file
  --format: string='yaml' # format of the output - supports `yaml` and `md`
  --keepFiles             # keep references to local files
] {
  if ($format == 'yaml') {
    ['---', (about|to yaml), '---', (
      doctable|if ($keepFiles) {
        $in
      } else {
        reject -i defined_in source
      }
      |to yaml)]
    |str join "\n"
    |_save -f $filepath
  } else if ($format == 'md') {
    doctable
    |each {|symbol|
      let path = $filepath|path join ($symbol.name + '.md')
      $symbol.description|_save -f $path
      $path
    }
  }
}

# Returns the header section for the currently mounted doctable
export def about [] {
  $env.PKD_CURRENT.about
}

# Returns the body section for the currently mounted doctable
export def doctable [] {
  $env.PKD_CURRENT.doctable
}

# Returns configuration value for $name
export def config [name:string] {
  $env.PKD_CONFIG|get $name
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
  let commandId = $command|default ''|cache command-to-id

  if ($type == 'string') {
    let file = (open $docs|from yaml)
    $env.PKD_CURRENT = {
      about: $file.0
      doctable: $file.1
    }
  } else if ($type == 'closure') {
    $env.PKD_CURRENT = if ($commandId in (cache|get name)) {
      open $"(cache repository)/($commandId)"|from msgpackz
    } else {
      let result = do $docs
      if ($result == null) {
        return
      } else {
        $result
      }
    }
  } else if ($type == 'nothing') {
    return
  } else {
    $env.PKD_CURRENT = $docs
  }

  if ($command != null) {
    cache-docs $commandId $env.PKD_CURRENT
  }

  if ($command != null) {
    $command
    |history doctables add
  }

  history symbols clear

  $"(doctable|length) symbols found\nUsing doctable ((about).name)~((about).version?)"
}

def cache-docs [name:string, docs:record] {
  cache init

  $docs
  |to msgpackz
  |_save -f $"(cache repository)/($name)"

  while (du (cache repository)|get 0.apparent) > (config cache_max_size) {
    rm (ls (cache repository)|sort-by modified|first).name
  }
}

# Returns current pikadoc version
export def version [] {
  $env.PKD_VERSION
}

# Returns the current doctable, unabridged
export def full [] {
  $env.PKD_CURRENT
}