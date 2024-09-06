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
  pythonCommand: {|...args:string|
    run-external 'python3' ...$args
  }
  npmCommand: {|...args:string|
    run-external 'npm' ...$args
  }
  npxCommand: {|...args:string|
    run-external 'npx' ...$args
  }
  pagerCommand: {|file?:string, line?:int|
    if ($file == null) {
      less
    } else if ($line == null) {
      less $file
    } else {
      less $"+($line)" -N $"($file)"
    }
  }
}

print ($"**Welcome to pikadoc** - to get started, type `doc tutor`"|glow -sauto)
