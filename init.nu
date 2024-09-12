let PROMPT_COMMAND_OLD = $env.PROMPT_COMMAND
$env.PROMPT_COMMAND = {||
  $"pikadoc \(($env.PKD_CURRENT?.about?.generator?): ($env.PKD_CURRENT?.about.name|default 'none')\) (do $PROMPT_COMMAND_OLD)"
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
  doc use $docs $command
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
    each { select '#'? ns? name? kind? summary? }
    |table -i false
  }
  table_max_rows: 20
}

let config = $env.config|upsert hooks {
  display_output: {
    let output = $in
    let output_type = $output|describe

    let is_output_list = (
      ($output_type|str starts-with 'list<') or
      ($output_type|str starts-with 'table<#: int')
    )

    let should_page = (
      $env.pkd.page_output and
      $is_output_list and
      ($output|length) > $env.PKD_CONFIG.table_max_rows
    )
    let should_summarize = $env.pkd.summarize_output

    $env.pkd.page_output = false
    $env.pkd.summarize_output = false

    if ($should_summarize and ($output_type|str starts-with 'record<#: int')) {
      $output.'#'|doc history symbols add
      $output|do $env.PKD_CONFIG.present_symbol_command
    } else if ($is_output_list) {
      if ($should_page) {
        doc page results use $output
        doc page
      } else {
        $output
      }
      |if ($should_summarize) {
        do $env.PKD_CONFIG.summarize_command
      } else {
        $in
      }
    } else {
      if ($is_output_list) {
        doc page results clear
      }

      $output
    }
  }
}
$env.config = $config

$env.pkd = {
  summarize_output: false
  page_output: false
  symbol_history: []
}

alias 'doc save' = doc doctable save
alias 'doc more' = doc page next

print ($"**Welcome to pikadoc** - to get started, type `doc tutor`"|glow -sauto)
