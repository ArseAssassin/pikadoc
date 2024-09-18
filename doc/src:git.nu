use pkd.nu
use lib.nu

alias 'lib-add' = lib add

# Runs $generators against git $repo, cloning only files within $subfolder
export def --env 'lib add' [
  generators:list<closure>
  repo:string
  subfolder:string='.'
] {
  lib concat (do {
    if (not ($env.PKD_TEMP|path exists)) {
      mkdir $env.PKD_TEMP
    }
    cd $env.PKD_TEMP

    let git_output = git clone --no-checkout --depth=1 --filter=tree:0 $repo|complete

    let dir = if ($git_output.exit_code == 0) {
      $git_output.stderr|parse "Cloning into '{name}'{rest}"|get 0.name
    } else if ($git_output.exit_code == 128) {
      $git_output.stderr|parse "fatal: destination path '{name}'{rest}"|get 0.name
    }

    cd $dir
    git sparse-checkout set --no-cone $subfolder
    git checkout

    $generators
    |each {|gen|
      do --env $gen
      pkd full
    }
  })
}