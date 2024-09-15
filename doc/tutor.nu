# Shows the pikadoc tutorial.
export def main [
  page:int=1 # page to show
] {
  help

  let tutorials = (
    $env.PKD_CURRENT.doctable
    |zip 0..
    |each {|row| $row.0|merge { '§': $row.1 }}
    |where {$in.name|str starts-with 'Tutorial'}
  )
  print ($tutorials|get ($page - 1)|do $env.PKD_CONFIG.present_symbol_command)

  if ($page < ($tutorials|length)) {
    print ($"Page ($page)/($tutorials|length). Type `doc tutor ($page + 1)` to show the next page")
  } else {
    print ($"Page ($page)/($tutorials|length). For more information about specific commands, use `doc <command> --help`.")
  }
}