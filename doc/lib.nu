use helpers.nu

def lib [] {
  $env.pkd.lib
}

export def index [] {
  lib|each { helpers doctable id }
}

export def --env add [mount?:closure] {
  let doctable = (
    if ($mount != null) {
      do {
        do --env $mount
        $env.PKD_CURRENT
      }
    } else {
      $env.PKD_CURRENT
    }
  )
  $env.pkd.lib = (
    lib
    |append $doctable
    |uniq
  )

  index
}

export def --env use [doctable] {
  let doctable = if (($doctable|describe) == 'string') {
    let query = $doctable|str downcase
    (
      lib
      |where {
        (($in.about.name|str downcase) == $query) or (
          $in|helpers doctable id|str downcase) == $query
      }
      |first
    )
  } else {
    lib|get $doctable
  }

  do --env $env.DOC_USE $doctable
}

export def query [query:closure] {
  lib
  |each {|doctable|
    do {
      do --env $env.DOC_USE $doctable

      do $query
      |each {|row| $row|merge {
        ns: $"($doctable.about.name): ($row.ns?)"
      } }
    }
  }
  |flatten
  |sort-by relevance
}