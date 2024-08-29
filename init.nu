let PROMPT_COMMAND_OLD = $env.PROMPT_COMMAND
$env.PROMPT_COMMAND = {||
  $"pikadoc \(($env.PKD_CURRENT?.about.name|default 'none')\) (do $PROMPT_COMMAND_OLD)"
}

$env.DOC_USE = {|docs, command?:string|
  doc use $docs $command
}

print ($"**Welcome to PikaDoc** - to get started, type:"|mdcat)
print ("`doc src:nushell use doc; doc`"|mdcat)
