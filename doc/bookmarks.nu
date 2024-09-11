use helpers.nu

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

export def current [] {
  bookmarks|get -i (current-name)|default []
}

export def add [index?:int] {
  update { append $index|uniq }
}

export def remove [index:int] {
  update { filter { $in != $index }  }
}

export def clear [] {
  update {|| [] }
}