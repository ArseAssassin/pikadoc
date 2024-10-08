# Generates a doctable from Python `$module`. Invokes `$env.PKD_CONFIG.python_command` to run a script using `python3` found using PATH. Doesn't install packages.
#
# ### Examples:
# ```nu
# # Generates a doctable from a locally installed package
# > doc src:python use flask
#
# # Generates a doctable from a locally installed package
# > doc src:python use flask
# ```
export def --env use [module:string] {
  let generatorCommand = $"src:python use ($module|to nuon)"

  do --env $env.DOC_USE {||
    let parsed = (
      do $env.PKD_CONFIG.python_command $"($env.PKD_HOME)/doc/src:python.py" $module
      |lines
      |last
      |from json
    )

    let description = $parsed.about?.description?|default ''

    {
      about: ({
        name: $module
        text_format: 'rst'
        generator: 'src:python'
        generator_command: $generatorCommand
        language: 'python'
      }
      |merge $parsed.about
      |merge {
        description: (
          match ($parsed.packageMetadata?.descriptionContentType) {
            'text/x-rst' => { $description|pandoc -f rst -tgfm-raw_html }
            'text/markdown' => { $description|pandoc -f gfm -tgfm-raw_html }
            _ => { $description }
          }
        )
      }
      )
      doctable: (
        $parsed.doctable
      )
    }
  } $generatorCommand
}