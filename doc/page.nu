# Shows current page of search results
export def --env main [] {
  if ($env.pkd?.results? == null) {
    "No more results. Use `doc` to search current doctable."
  } else {
    $env.pkd.summarize_output = $env.pkd.pager_summarize
    $env.pkd.skip_pager = true

    $env.pkd.results
    |skip $env.pkd.cursor
    |take $env.PKD_CONFIG.table_max_rows
  }
}

# Browses to the next page of search results. `doc more` is an alias of this
export def --env next [] {
  $env.pkd.cursor += $env.PKD_CONFIG.table_max_rows
  let output = main

  if ($env.pkd.cursor + $env.PKD_CONFIG.table_max_rows >= ($env.pkd.results|length)) {
    $env.pkd.results = null
    $env.pkd.cursor = 0
  }

  $output
}

# Browses to the previous page of search results
export def --env previous [] {
  $env.pkd.cursor -= $env.PKD_CONFIG.table_max_rows
  if ($env.pkd.cursor < 0) {
    $env.pkd.cursor = 0
  }
  main
}

# Mounts $results for use by the pager
export def --env 'results use' [results, should_summarize=true] {
  $env.pkd.results = $results
  $env.pkd.cursor = 0
  $env.pkd.pager_summarize = $should_summarize
}

# Clears current results from the pager
export def --env 'results clear' [] {
  results use null
}
