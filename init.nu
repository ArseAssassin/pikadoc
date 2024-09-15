let PROMPT_COMMAND_OLD = $env.PROMPT_COMMAND
$env.PROMPT_COMMAND = {||
  $"pikadoc (if ((doc lib index) != []) { '*' })\(($env.PKD_CURRENT?.about?.generator?): ($env.PKD_CURRENT?.about.name|default 'none')\) (do $PROMPT_COMMAND_OLD)"
}

let PROMPT_COMMAND_RIGHT_OLD = $env.PROMPT_COMMAND_RIGHT
$env.PROMPT_COMMAND_RIGHT = {
  if ($env.pkd?.results? != null) {
    $"\((($env.pkd.results|length) - $env.PKD_CONFIG.table_max_rows - $env.pkd.cursor) results more...\)"
  } else {
    do $PROMPT_COMMAND_RIGHT_OLD
  }
}

$env.DOC_USE = {|docs, command?:string|
  doc pkd use $docs $command
}

$env.DOC = {|query|
  doc $query
}

$env.PKD_CONFIG = {
  cache_max_size: ('100Mb'|into filesize)
  python_command: {|...args:string|
    run-external 'python3' ...$args
  }
  npm_command: {|...args:string|
    run-external 'npm' ...$args
  }
  npx_command: {|...args:string|
    run-external 'npx' ...$args
  }
  tidy_command: {||
   tidy -c --output-xhtml yes --doctype omit
  }
  pager_command: {|file?:string, line?:int|
    let s = $in
    if ($file == null and $s != null) {
      if (($s|lines|length) >= (term size).rows) {
        $s|less -r
      } else {
        $s
      }
    } else if ($line == null) {
      less -r $file
    } else {
      less $"+($line)" -N $"($file)"
    }
  }
  present_symbol_command: {
    doc present
    |do $env.PKD_CONFIG.pager_command
  }
  summarize_command: {
    let table = $in

    if ('matches' in ($table|columns)) {
      $table|select '§'? ns? name? kind? matches
    } else if ('signatures' in ($table|columns)) {
      $table
      |upsert signatures {|row| $row.signatures?|default []|doc present-signatures }
      |select '§'? ns? name? kind? summary? signatures?
    } else {
      $table
      |select '§'? ns? name? kind? summary?
    }
  }
  table_max_rows: 20
}

let config = $env.config|upsert hooks {
  display_output: {
    let output = $in
    let output_type = $output|describe

    let is_output_list = (
      (
        ($output_type|str starts-with 'list<any') and
        ('§' in ($output|columns))
      ) or
      ($output_type|str starts-with 'table<§: int')
    )

    let should_page = (
      $env.pkd.page_output == true and
      $env.pkd.skip_pager != true
    )
    let should_skip_pager = $env.pkd.skip_pager? == true

    let should_summarize = $env.pkd.summarize_output == true

    $env.pkd.page_output = true
    $env.pkd.summarize_output = true
    $env.pkd.skip_pager = false

    if (
      $should_summarize and
      ($output_type|str starts-with 'record<§: int')
    ) {
      $output.'§'|doc history symbols add
      $output|do $env.PKD_CONFIG.present_symbol_command
    } else if ($is_output_list) {
      if (not $should_skip_pager) {
        doc page results clear
      }

      $output
      |if ($should_page) {
        let results = $in

        if (($output|length) > $env.PKD_CONFIG.table_max_rows) {
          doc page results use $results $should_summarize
          doc page
        } else {
          $results
        }
      } else {
        $in
      }
      |if ($should_summarize) {
        do $env.PKD_CONFIG.summarize_command
      } else {
        $in
      }
      |table -i false
    } else {
      $output
    }
  }
}
$env.config = $config

$env.pkd = {
  summarize_output: true
  page_output: true
  symbol_history: []
  lib: []
  cursor: 0
  page_summarize: true
  skip_pager: false
  results: null
}

alias 'doc use' = doc pkd use
alias 'doc save' = doc pkd save
alias 'doc version' = doc pkd version
alias 'doc more' = doc page next

source (if ('~/.config/pikadoc/pikadocrc.nu'|path exists) {
  '~/.config/pikadoc/pikadocrc.nu'
} else {
  'pikadocrc.example.nu'
})

print ($"**Welcome to pikadoc** - to get started, type `doc tutor`"|glow -sauto)
