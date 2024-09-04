use helpers.nu
use src:jsdoc.nu

# Generates doctable for npm package `package`. Parses .md files
# found in the package repository and attempts to parse jsdocs
# if available.
#
# ### Examples:
# ```nushell
# # Generate docs for ramda.js npm package
# > doc src:npm use ramda
#
# # Generate docs for an old version
# > doc src:npm use ramda@0.29.1
# ```
export def --env use [
  package:string # package name, including version
] {
  let generatorCommand = $"src:npm use ($package|to nuon)"
  do --env $env.DOC_USE {
    let tempProject = '/tmp/pikadoc-npm'
    let packageName = $package|split row '@'|first

    mkdir $tempProject
    cd $tempProject

    let install = (
      run-external $"($env.PKD_HOME)/doc/npm-install" "--no-save" $package
      |complete
    )

    if ($install.exit_code != 0) {
      print $install
      print "Something went wrong during npm install"
      return
    }
    cd ("node_modules"|path join $packageName)

    let packageMeta = open package.json
    let mainDir = $packageMeta.main?|default '.'|path dirname

    {
      about: {
        name: $packageMeta.name
        generator: 'src:npm'
        version: $packageMeta.version
        text_format: 'markdown'
        generator_command: $generatorCommand
      }
      doctable: ((
        ls **/*.md
        |each {
          let file = $in.name
          let md = (open $file)

          {
            name: $file
            kind: 'user guide'
            defined_in: {
              file: $file
            }
            description: $md
            summary: ($md|helpers markdown-to-summary)
          }
        }
      ) ++ (if (src:jsdoc is-jsdoc-module $mainDir) {
        do {||
          src:jsdoc use $mainDir
          $env.PKD_CURRENT.doctable
        }
      } else {
        []
      }))
    }
  } $generatorCommand

}