use helpers.nu
use history.nu

def current-name [] {
  $env.PKD_CURRENT.about.name
}

def bookmarks [] {
  helpers profile get 'bookmarks' {}
}

def update [update:closure] {
  helpers profile set 'bookmarks' (
    bookmarks
    |merge {
      (current-name):
      (current|do $update)
    }
  )
}

# Returns the list of bookmarked symbol indices in current doctable
export def current [] {
  bookmarks|get -i (current-name)|default []
}

# Adds $index to the list of bookmarked symbols. If $index is not defined, add the last symbol viewed
export def add [
  index?:int # index of the symbol to bookmark
  ] {

  let _index = if ($index == null) {
    history symbols|last
  } else {
    $index
  }
  update { append $_index|uniq }
}

# Removes $index from the list of bookmarked symbols
export def remove [
  index:int # index of the symbol to remove
  ] {
  update { filter { $in != $index }  }
}

# Clears the bookmark list for this doctable
export def clear [] {
  update {|| [] }
}