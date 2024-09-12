# Returns the path to the cache directory that's currently
# being used.
export def repository [] {
  $"($env.PKD_CONFIG_HOME)/doc-cache"
}

# Returns a list of doctables cached in the local filesystem.
# `cache path` returns the directory used for storing files.
# See `doc cache clear` for details on cache management.
export def main [] {
  init
  ls -s (repository)
}

# Initializes cache
export def init [] {
  if (not (repository|path exists)) {
    mkdir (repository)
  }
}

# Clears all locally cached doctables. Useful for updating
# stale documents.
#
# Calling this manually shouldn't be necessary as pikadoc
# automatically clears old files when cache size surpasses
# `$env.PKD_CONFIG.cache_max_size`.
#
# The default max cache size is 100Mb.
#
# Examples
#
# # adjust max cache size
# let pkdConfig = $env.PKD_CONFIG|merge { cache_max_size: ('200Mb'|into filesize) }; $env.PKD_CONFIG = $pkdConfig
export def clear [] {
  init

  rm -f ((repository) + '/*'|into glob)
}

# Escapes special characters in input command to use it as a valid Unix path
export def command-to-id [] string -> string {
  str replace -a '/' '__'
}