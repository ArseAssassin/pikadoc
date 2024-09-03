export def main [page:int=1] {
  do --env $env.DOC_USE $"($env.PKD_HOME)/user_guide.pkd"

  let tutorials = $env.PKD_CURRENT.doctable|where {$in.name|str starts-with 'Tutorial'}
  print (do --env $env.DOC ($page - 1))

  if ($page < ($tutorials|length)) {
    print ($"Page ($page)/($tutorials|length). Type `doc tutor ($page + 1)` to show the next page")
  } else {
    print ($"Page ($page)/($tutorials|length). For more information about specific commands, use `doc <command> --help`.")
  }
}