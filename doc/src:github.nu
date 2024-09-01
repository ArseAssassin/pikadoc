export def --env use [repo:string] {
  let metadata = http get $"https://api.github.com/repos/($repo)"
  let branch = $metadata.default_branch
  let docs = (
    http get $"https://api.github.com/repos/($repo)/git/trees/($branch)?recursive=true"
    |get tree
    |where {|| ($in.path|str ends-with -i '.md') and not ($in.path|str starts-with '.github') and ($in.path|find -i -r 'test.*/') == null}

  )

  print $"Downloading ($docs|length) documents"

  do --env $env.DOC_USE {
    about: {
      name: $repo
      text_format: 'markdown'
    }
    doctable: (
      $docs
      |each {|md|
        print -n .

        $md
        |merge {
          doc: (http get $"https://raw.githubusercontent.com/($repo)/($branch)/($md.path)")
          ns: 'repo'
          url: $"https://github.com/($repo)/blob/($branch)/($md.path)"
        }}
      |if ($metadata.has_wiki) {
        $in
        |append (do {
          let repoPath = "/tmp/" + ($repo|parse '{user}/{name}'|get 0.name) + '.wiki/'

          print ''
          print $"Repository has wiki enabled, cloning into ($repoPath)"

          git -C /tmp/ clone $"https://github.com/($repo).wiki.git"

          cd $repoPath
          let wikiPages = (
            ls **/*.md
            |each {|| {
              path: $in.name
              ns: 'wiki'
              url: $"https://github.com/($repo)/wiki/($in.name|str substring ..-3)"
              doc: (open $"($repoPath)($in.name)")
            }}
          )

          cd /
          rm -rf $repoPath

          $wikiPages
        })
      } else {
        $in
      }
      |each {|md|
        ({
          name: $md.path
          description: $md.doc
          ns: $md.ns
          url: $md.url
          summary: (
            $md.doc
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