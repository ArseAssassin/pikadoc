export use cache.nu
export use history.nu
export use bookmarks.nu
export use page.nu
export use lib.nu
export use pkd.nu
export use tutor.nu

export use s.nu

export use src:devdocs.nu
export use src:man.nu
export use src:sqlite.nu
export use src:psql.nu
export use src:python.nu
export use src:openapi.nu
export use src:nushell.nu
export use src:github.nu
export use src:jsdoc.nu
export use src:npm.nu
export use src:godot.nu
export use src:html.nu
export use src:md.nu
export use src:git.nu

# Filters current doctable using $query. If $query is null, returns full list of all symbols in current doctable. If $query is `int`, returns symbol with that index.
#
# By default search results are paged according to `$env.PKD_CONFIG.table_max_rows` (use `doc page next` to show more results). In addition, all results are summarized using `$env.PKD_CONFIG.summarize_command`.
#
# By default, additional filtering is done when displaying symbols. See `doc output` for more information.
#
# ### Examples:
#
# ```nu
# # Return paged list of all symbols in doc
# doc
#
# # Return list of all symbols matching string 'src:'
# doc 'src:'
#
# # Show symbol #4
# doc 4
# ```
export def --env main [
  query? # (string) query to search for, (int) symbol to select
] {
  let input = $in
  let docs = if ($input != null) {
    $input
  } else if ('PKD_CURRENT' in $env) {
    pkd doctable
    |add-doc-ids
  } else {
    return "No docfile currently selected. Type `doc use <path>` to select a docfile to use."
  }

  if (($query|describe) == 'int') {
    $docs|where {$in.'§' == ($query)}|first
  } else if (($query|describe) == 'string') {
    let query = ($query|str downcase)
    let search = (
      $docs|find $query -c ['name', 'summary']
    )

    $search
    |insert relevance {|row| (
      (($row.name|ansi strip|str downcase|str index-of $query|if ($in == -1) { 100 } else { $in }) * 100) +
      (($row.name|ansi strip|str distance $query)) * 100 +
      (($row.summary?|default ''|ansi strip|str downcase|find $query|length) * -10) +
      ($row.description?|default ''|ansi strip|str downcase|find $query|length) * -1
    )}
    |sort-by relevance
  } else {
    $docs
  }
}

# Controls displayed output. If `--all` is set, displayed results won't be paged. If `--full` is set, symbols won't be summarized or formatted for output.
#
# ### Examples:
# ```nu
# # Dump all symbols formatted as a raw table
# doc|doc output --full --all
#
# # Dump the raw data table for symbol #10
# doc|get 10|doc output --full
# ```
export def --env output [
  --all
  --full
  ] {
  let result = $in

  $env.pkd.page_output = not $all
  $env.pkd.summarize_output = not $full

  $result
}

# Returns a table of recently used symbols
export def --env history [] {
  let docs = main

  history symbols
  |reverse
  |each {|index| $docs|get $index}
}

# Returns a table of bookmarked symbols
export def --env bookmarks [] {
  let docs = main

  bookmarks current
  |reverse
  |each {|index| $docs|get $index}
}

# Returns the children of symbol `$in` as indicated by `belongs_to`
export def --env children [] {
  let docId = get id?

  if ($docId != null) {
    main
    |where belongs_to? == $docId or id? == $docId
  } else {
    []
  }
}

# Returns the parent of symbol `$in` as indicated by `belongs_to`
export def --env parent [] {
  let docId = get belongs_to?

  if ($docId != null) {
    main
    |where id? == $docId
    |first
  } else {
    null
  }
}

# Searches the descriptions of all symbols in the current doctable for $query. System grep is used for matching output.
export def --env search [
  query:string # query to search for
  ] {
  if (('PKD_CURRENT' in $env) != true) {
    print "No docfile currently selected. Type `doc use <path>` to select a docfile to use."
    return
  }

  main
  |find $query -c ['description']
  |insert relevance {|row| (
    $row.description
    |ansi strip
    |grep -F -i -o $query
    |lines
    |length
  ) * -1}
  |sort-by relevance
  |insert matches {|row|
    $row.description
    |grep -F -i $query -A0 -B0 --group-separator='...' -m 5
  }
  |select '§' name matches relevance
}

def add-doc-ids [] {
  zip 0..|each {|vals| {'§': $vals.1}|merge $vals.0}
}

def --env present-list [] {
  paginate (result-lines) true
}

# Creates a string summary of symbol `$in`
export def summarize [] {
  select '§'? ns? name? kind? summary?
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
}

def present-type [] {
  let type = $in
  $"($type.name?)(if (($type.name?|default '') != '' and ($type.type?|default '') != '') { ':' })($type.type?)(if ($type.optional? == true) { '?' })(if ($type.rest? == true) {
    '...'
  })(if ($type.default? != null) {
    '=' + ($type.default|to nuon)
  })"
}

# Presents symbol signatures `$in` as a string
export def present-signatures [] {
  each {|sig|
    (
      $sig
      |where kind != 'return'
      |each { present-type }
      |str join ", "
    ) + (
      $sig
      |where kind == 'return'
      |each { present-type }
      |str join ", "
      |if ($in != '') {
        ' -> ' + $in
      } else {
        $in
      }
    )
    |str trim
  }
  |str join "\n"
}

def present-param [] {
  let param = $in
  let type = $param|present-type

  (if ($type != '') {
    $"> `($type)`\n"
  } else {
    ''
  }) + $"> ($param.description?)"
}

def present-body [] {
  let output = $in
  let params = $output.signatures?.0?
    |default []
    |do {take ((($in|length) - 1)|if ($in < 0) { 0 } else { $in })}
    |where {(($in.description?|default '') != '' and ($in.name?|default '') != '')}

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
      let language = (pkd about).language?|default ''
      $"\n\nExamples:\n```($language)\n" + (
        $output.examples
        |str join "\n\n"
      ) + "\n```"
    } else {
      ""
    }
  )
}

# Presents the symbol `$in` as formatted output.
#
# ### Examples:
# ```nu
# doc|get 0|doc present
# ```
export def present [] {
  let output = $in
  let trimmedOutput = if ($output.summary? == '' or ($output.summary?|default ''|str trim) ==
      ($output.description?|default ''|str trim)) {
    $output|reject summary? description?
  } else {
    $output|reject description?
  }
  |reject examples?

  let meta = (
    $trimmedOutput
    |maybe-update signatures {|| present-signatures }
    |insert source_available {|row| $row.source? != null or $row.defined_in? != null}
    |reject source?
    |table --expand
  )

  if ((pkd about).text_format? == 'markdown') {
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
}

def maybe-update [name, value] {
  if ($in|get -i $name) != null {
    update $name $value
  } else {
    $in
  }
}

# Show sources for symbol $in. Fails if `$symbol.defined_in` and `$symbol.source` are undefined. `$env.PKD_CONFIG.pager_command` is used to show the results.
#
# ### Examples:
# ```nu
# # Show sources for symbol §0
# doc|get 0|doc view-source
# ```
export def view-source [] {
  let symbol = $in

  if ($symbol.source? != null) {
    $symbol.source|do (pkd config pager_command)
  } else if ($symbol.defined_in?.file? != null and ($symbol.defined_in?.file?|path exists)) {
    do (pkd config pager_command) $symbol.defined_in.file ($symbol.defined_in.line?|default 0)
  } else {
    print "Couldn't open sources for reading"
  }
}

# Mounts pikadoc user guide as the current doctable
export def --env help [] {
  do --env $env.DOC_USE ($env.PKD_HOME|path join 'user_guide.pkd')
}

# Selects next symbol in current doctable
export def next [] {
  let current = history symbols|get 0?|default (-1)
  main|get ($current + 1)
}

# Selects previous symbol in current doctable
export def previous [] {
  let current = history symbols|get 0?|default 0
  main|get ($current - 1|if ($in < 0) { 0 } else { $in })
}