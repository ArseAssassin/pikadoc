export def --env main [] {
  $env.pkd.summarize_output = true

  $env.pkd.results
  |skip $env.pkd.cursor
  |take $env.PKD_CONFIG.table_max_rows
}

export def --env next [] {
  $env.pkd.cursor += $env.PKD_CONFIG.table_max_rows
  let output = main

  if ($env.pkd.cursor + $env.PKD_CONFIG.table_max_rows >= ($env.pkd.results|length)) {
    $env.pkd.results = null
    $env.pkd.cursor = 0
  }

  $output
}

export def --env previous [] {
  $env.pkd.cursor -= $env.PKD_CONFIG.table_max_rows
  if ($env.pkd.cursor < 0) {
    $env.pkd.cursor = 0
  }
  main
}

export def --env 'results use' [results] {
  $env.pkd.results = $results
  $env.pkd.cursor = 0
}

export def --env 'results clear' [] {
  results use []
}
