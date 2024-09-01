export def repository [] {
  $"($env.PKD_CONFIG_HOME)/doc-cache"
}

# Returns `ls` of doctables cached in the local filesystem.
# `cache path` returns the directory used for storing files.
# See `doc cache clear` for details on cache management.
export def main [] {
  init
  ls (repository)
}

def init [] {
  if (not (repository|path exists)) {
    mkdir (repository)
  }
}

# Clears all locally cached doctables. Useful for updating
# stale documents.
#
# Calling this manually shouldn't be necessary as pikadoc
# automatically clears old files when cache size surpasses
# `$env.PKD_CONFIG.cacheMaxSize`.
#
# The default max cache size is 100Mb.
#
# Examples
#
# # adjust max cache size
# let pkdConfig = $env.PKD_CONFIG|merge { cacheMaxSize: ('200Mb'|into filesize) }; $env.PKD_CONFIG = $pkdConfig
export def clear [] {
  init

  rm ((repository) + '/*')
}

