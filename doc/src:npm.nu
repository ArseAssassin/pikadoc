use helpers.nu
use src:jsdoc.nu

# Generates doctable for npm package $packageName. Parses .md files
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
  packageName:string # package name, including version
] {
  let package = if (not ('@' in $packageName) and ('package.json'|path exists)) {
    let packageJson = open 'package.json'
    let dependencies = $packageJson.devDependencies|merge $packageJson.dependencies

    if ($packageName in $dependencies) {
      $"($packageName)@($dependencies|get $packageName)"
    }
  } else {
    $packageName
  }
  let generatorCommand = $"src:npm use ($package|to nuon)"
  do --env $env.DOC_USE {
    let tempProject = '/tmp/pikadoc-npm'
    let packageName = $package|split row '@'|first

    mkdir $tempProject
    cd $tempProject

    let install = (
      do $env.PKD_CONFIG.npm_command "install" "--no-save" $package
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
        version: $packageMeta.version
        text_format: 'markdown'
        generator: 'src:npm'
        generator_command: $generatorCommand
        language: 'javascript'
        license: (
          open (
            ['LICENSE', 'LICENSE.md', 'LICENSE.txt']
            |where {path exists}
            |first
          )
        )
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
              file: ($file|path expand)
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