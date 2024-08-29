export def --env use [repo:string] {
  do --env $env.DOC_USE {
    about: {
      name: $repo
      text_format: 'markdown'
    }
    doctable: (
      http get $"https://api.github.com/repos/($repo)/git/trees/main?recursive=true"
      |get tree
      |where {|| ($in.path|str ends-with '.md') and not ($in.path|str starts-with '.github') and not ($in.path|str starts-with 'test/command/')}
      |each {|md|
        print -n .

        ({
          name: $md.path
          description: (http get $"https://raw.githubusercontent.com/($repo)/main/($md.path)")
        })}
    )
  } $"src:github use ($repo)"

}