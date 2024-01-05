let PROMPT_COMMAND_RIGHT_OLD = $env.PROMPT_COMMAND_RIGHT
$env.PROMPT_COMMAND_RIGHT = {||
  if ('PKD_ABOUT' in $env) {
    $"pikadoc:($env.PKD_ABOUT.name)"
  } else {
    do $PROMPT_COMMAND_RIGHT_OLD
  }
}

print ($"**Welcome to PikaDoc** - to get started, type:"|mdcat)
print ("`doc src:nushell use doc; doc`"|mdcat)
