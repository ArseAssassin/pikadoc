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

        let doc = http get $"https://raw.githubusercontent.com/($repo)/main/($md.path)"

        ({
          name: $md.path
          description: $doc
          summary: (
            $doc
            |pandoc -f gfm -t html --wrap=none
            |hxnormalize -x
            |hxunent -b
            |xmlstarlet select -t --value-of '//p[contains(., '.')][1]'
            |lines
            |each {|| str trim}
            |str join ' '
            |split row '.'
            |get 0
            |str trim)
        })}
    )
  } $"src:github use ($repo)"

}