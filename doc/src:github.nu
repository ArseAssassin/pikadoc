def download-file [repo:string, branch:string, path:string] {
  http get $"https://raw.githubusercontent.com/($repo)/($branch)/($path|url encode)"
}

# Attempts to download and use all available documentation from
# the given GitHub repo using the public API. `repoName` should be
# the name of the repository, including the name of the owner.  If it
# doesn't include the name of the owner, GitHub search API is used to
# select the most popular repo with the given name. If `branchName` is
# not passed an argument, default branch of the project is chosen.
#
# ### Examples:
# ```nushell
# # Use the docs available in the pikadoc GitHub repository
# > doc src:github use ArseAssassin/pikadoc
#
# # Use the docs available in the nushell GitHub repository
# > doc src:github use nushell
# ```
export def --env use [
  repoName:string,    # name of the repo, including the owner
  branchName?:string  # name of the branch
] {
  do --env $env.DOC_USE {||
    let repo = if ('/' in $repoName) {
      $repoName
    } else {
      http get $"https://api.github.com/search/repositories?q=($repoName)&per_page=1"
      |get items.0.full_name
    }

    let branch = if ($branchName == null) {
      let metadata = http get $"https://api.github.com/repos/($repo)"
      $metadata.default_branch
    } else {
      $branchName
    }

    let fileTree = (
      http get $"https://api.github.com/repos/($repo)/git/trees/($branch)?recursive=true"
      |get tree
    )
    let docs = (
      $fileTree
      |where {|| ($in.path|str ends-with -i '.md') and not ($in.path|str starts-with '.github') and ($in.path|find -i -r 'test.*/') == null}
    )
    let pkds = (
      $fileTree
      |where {($in.path|str ends-with -i '.pkd')}
      |each {|pkd|
        print -n .

        let doc = download-file $repo $branch $pkd.path|from yaml

        $doc.1
        |each {|symbol|
          $symbol|merge { belongs_to: $doc.0.name }
        }
      }
    )

    let mdDoctable = (
      $docs
      |each {|md|
        print -n .

        $md
        |merge {
          doc: (download-file $repo $branch $md.path)
          url: $"https://github.com/($repo)/blob/($branch)/($md.path)"
        }}
        # Disabled for now. GitHub incorrectly reports wiki as enabled for many
        # repositories, causing clone to fail.
        #
        # |if ($metadata.has_wiki) {
        #   $in
        #   |append (do {
        #     let repoPath = "/tmp/" + ($repo|parse '{user}/{name}'|get 0.name) + '.wiki/'

        #     print ''
        #     print $"Repository has wiki enabled, cloning into ($repoPath)"

        #     git -C /tmp/ clone $"https://github.com/($repo).wiki.git"

        #     cd $repoPath
        #     let wikiPages = (
        #       ls **/*.md
        #       |each {|| {
        #         path: $in.name
        #         ns: 'wiki'
        #         url: $"https://github.com/($repo)/wiki/($in.name|str substring ..-3)"
        #         doc: (open $"($repoPath)($in.name)")
        #       }}
        #     )

        #     cd /
        #     rm -rf $repoPath

        #     $wikiPages
        #   })
        # } else {
        #   $in
        # }
        |each {|md| ({
          name: $md.path
          description: $md.doc
          ns: $md.ns?
          kind: 'md doc'
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

    {
      about: {
        name: $repo
        text_format: 'markdown'
        generator: 'src:github'
        generator_command: $"src:github ($repoName)"
      }
      doctable: (
        [$mdDoctable, ($pkds|flatten)]|flatten
      )
    }
  } $"src:github use ($repoName)"
}