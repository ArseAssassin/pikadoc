export use cache.nu

export use s.nu
export use tutor.nu
export use src:devdocs.nu
export use src:man.nu
export use src:sqlite.nu
export use src:python.nu
export use src:openapi.nu
export use src:nushell.nu
export use src:github.nu
export use src:jsdoc.nu
export use src:npm.nu

# Returns a summarized table of available symbols in the
# currently selected doctable.
#
# If a `string` is passed as an argument, doctable will be
# filtered by `name` and `summary`. If an `int` is passed
# as an argument, only the selected symbol is presented.
# If a closure is passed as an argument, it'll be used to
# filter the full doctable before being summarized and paged.
#
# ### Examples:
# ```nushell
# # Return list of all symbols in current doctable
# > doc
#
# # Filter symbols by name in current doctable
# > doc 'add'
#
# # Show symbol at index 3
# > doc 3
#
# # Filter symbols by namespace
# > doc {|| where ns == 'inspect'}
#
# # Show symbols that are either functions or classes
# > doc {|| where kind in ['function', 'class']}
#
# # Show symbols that have a summary
# > doc {|| where summary != ''}
# ```
export def --env main [
  query? # name/index/closure to query for
] {
  if (('PKD_CURRENT' in $env) != true) {
    print "No docfile currently selected. Type `doc use <path>` to select a docfile to use."
    return
  }
  if (($query|describe) == 'int') {
    pkd-doctable|get $query|present
  } else if (($query|describe) == 'closure') {
    pkd-doctable
    |add-doc-ids
    |do $query
    |summarize-all
    |present-list
  } else if ($query != null) {
    let query = ($query|str downcase)
    let search = (
      pkd-doctable
      |add-doc-ids
      |find $query -c ['name', 'summary']
    )

    $search
    |insert dist {|row| (
      (($row.name|ansi strip|str downcase|str index-of $query|if ($in == -1) { 100 } else { $in }) * 100) +
      (($row.summary|ansi strip|str downcase|find $query|length) * -10) +
      ($row.description|ansi strip|str downcase|find $query|length) * -1
    )}
    |sort-by dist
    |reject dist
    |summarize-all
    |present-list
  } else {
    pkd-doctable
    |add-doc-ids
    |summarize-all
    |present-list
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
  |select '#' name results
  |present-list
}

def add-doc-ids [] {
  zip 0..|each {|vals| {'#': $vals.1}|merge $vals.0}
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

  let tableOutput = ($list|table -i false)

  if (($env.PKD_CURSOR + $resultLines) < ($docs|length)) {
    $"($tableOutput)\nShowing ($env.PKD_CURSOR + $resultLines) results out of ($docs|length), type `doc more` for more results"
  } else {
    $env.PKD_CURSOR = 0
    $tableOutput
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
  } else if ($type == 'string') {
    $docs|path expand|to nuon
  }
  |add-to-history
}

# Returns the header section for the currently mounted doctable
export def pkd-about [] {
  $env.PKD_CURRENT.about
}

# Returns the body section for the currently mounted doctable
export def pkd-doctable [] {
  $env.PKD_CURRENT.doctable
}

def show [] {
  less -S --chop-long-lines
}

def "from pkd" [] {
  from yaml
}

def summarize [] {
  select '#'? ns? name? kind? summary?
  |if ($in.ns? == null) {
    update ns ''
  } else {
    $in
  }
  |if ($in.kind? == null) {
    update kind ''
  } else {
    $in
  }
  |trim-record-whitespace
}

def summarize-all [] {
  each {|| summarize}
}

alias _save = save

# Saves doctable in the filesystem.
export def save [
  filepath: string        # path to use for saving the file
  --format: string='yaml' # format of the output - supports `yaml` and `md`
  --keepFiles             # keep references to local files
] {
  if ($format == 'yaml') {
    ['---', (pkd-about|to yaml), '---', (
      pkd-doctable|if ($keepFiles) {
        $in
      } else {
        reject -i defined_in
      }
      |to yaml)]
    |str join "\n"
    |_save -f $filepath
  } else if ($format == 'md') {
    pkd-doctable
    |each {|symbol|
      let path = $filepath|path join ($symbol.name + '.md')
      $symbol.description|_save -f $path
      $path
    }
  }

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

def present-type [] {
  let type = $in
  let name = $type|describe
  if ($name == 'list<list<any>>' or ($name|str starts-with 'list<table<')) {
    $type
    |each { present-type }
    |str join "\n"
  } else if ($name == 'list<any>' or ($name|str starts-with 'table<')) {
    $type
    |each { present-type }
    |str join " -> "
  } else if ($name|str starts-with 'record') {
    $"($type.name?)(if ($type.name? != null and $type.type? != null) { ':' })($type.type?)(if ($type.optional? == true) { '?' })(if ($type.rest? == true) {
      '...'
    })(if ($type.default? != null) {
      '=' + $type.default
    })"
  } else {
    $in
  }
}

def present-param [] {
  let param = $in
  let type = $param|present-type

  (if ($type != '') {
    $"> `($type)`\n"
  } else {
    ''
  }) + $"> ($param.description)"
}

def present-body [] {
  let output = $in
  let params = $output.signatures?.0?
    |default []
    |do {take ((($in|length) - 1)|if ($in < 0) { 0 } else { $in })}
    |where {(($in.description|default '') != '' and ($in.name|default '') != '')}

  ($output.description?|default '') + (
    $output
    |if (($params|length) > 0) {
      $"\n\nParams:\n($params|each {
        present-param
      }|str join "\n\n")"
    } else {
      ''
    }
  ) + (
    $output.signatures?.0?
    |if ($in != null and $in != []) {
      let returns = (
        $output.signatures.0
        |last
        |present-param
      )
      $"\n\nReturns:\n($returns)"
    } else {
      ''
    }
  ) + (
    |if ($output.examples? != null and $output.examples? != []) {
      $"\n\nExamples:\n($output.examples|str join "\n\n")"
    } else {
      ""
    }
  )
}

def pager [] {
  $in|do (pkd-config pagerCommand)
}

# Presents the symbol passed in as input as tidily formatted output.
# Useful for showing the results of custom queries.
#
# ### Example:
#     ```> doc pkd-doctable|get 0|doc present```
export def present [] {
  let output = $in
    |trim-record-whitespace

  let trimmedOutput = if ($output.summary? == '' or ($output.summary?|default ''|str trim) ==
      ($output.description?|default ''|str trim)) {
    $output|reject summary? description?
  } else {
    $output|reject description?
  }
  |reject examples? source?

  let meta = (
    $trimmedOutput
    |maybe-update signatures {|| present-type }
    |table --expand
  )

  if ((pkd-about).text_format? == 'markdown') {
    let body = (
      $output
      |present-body
      |glow -s auto
      |complete
      |get stdout
    )

    $"($meta)\n\n($body)"
  } else {
    $"($meta)\n\n($output.description?)"
  }
  |pager
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

# Returns path to the history file that's currently in use
export def history-file [] {
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
  let history = _history
  $history
  |each {|| $"doc ($in)"}
  |reverse
}

# Deletes the history file
export def 'history clear' [] {
  rm (history-file)
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

def cache-docs [name:string, docs:record] {
  cache init

  $docs
  |to msgpackz
  |_save -f $"(cache repository)/($name)"

  while (du (cache repository)|get 0.apparent) > $env.PKD_CONFIG.cacheMaxSize {
    rm (ls (cache repository)|sort-by modified|first).name
  }
}

# If symbol selected with `index` has sources available
# (`$symbol.defined_in.file` can be found in the filesystem), opens it
# for reading using `$env.PKD_CONFIG.pagerCommand`.
#
# ### Examples:
# ```nushell
# # Show sources for symbol 0 using `less`
# doc view-source 0
# ```
export def view-source [
  index:int # index of the symbol
] {
  let symbol = pkd-doctable|get -i $index|get defined_in?
  if ($symbol.file? != null and ($symbol.file?|path exists)) {
    do (pkd-config pagerCommand) $symbol.file ($symbol.line?|default 0)
  } else {
    print "Couldn't open sources for reading"
  }
}

export def pkd-config [name:string] {
  $env.PKD_CONFIG|get $name
}