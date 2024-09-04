let PROMPT_COMMAND_OLD = $env.PROMPT_COMMAND
$env.PROMPT_COMMAND = {||
  $"pikadoc \(($env.PKD_CURRENT?.about.name|default 'none')\) (do $PROMPT_COMMAND_OLD)"
}

$env.DOC_USE = {|docs, command?:string|
  doc use $docs $command
}

$env.DOC = {|query|
  doc $query
}

$env.PKD_CONFIG = {
  cacheMaxSize: ('100Mb'|into filesize)
  pagerCommand: {|file, line?|
    if ($line == null) {
      less $file
    } else {
      less $"+($line)" -N $"($file)"
    }
  }
}

print ($"**Welcome to pikadoc** - to get started, type `doc tutor`"|glow -sauto)
