use helpers.nu

def 'doctables value' [] {
  helpers profile get "doctable_history" []
}

def 'doctables set' [value] {
  helpers profile set "doctable_history" $value
}

# Returns a list of the last 50 doctables selected with `doc use`
export def doctables [] {
  doctables value
  |each {|| $"doc ($in)"}
  |reverse
}

# Deletes the history file
export def 'doctables clear' [] {
  doctables set []
}

# Adds $in to the doctable history
export def 'doctables add' [] {
  let cmd = $in
  doctables set (
    doctables value
    |prepend $cmd
    |uniq
  )
}

# Returns the list of recently viewed symbols
export def symbols [] {
  $env.PKD_SYMBOL_HISTORY?|default []
}

# Clears the list of recently viewed symbols
export def --env 'symbols clear' [] {
  $env.PKD_SYMBOL_HISTORY = []
}

# Adds $in to the list of recently viewed symbols
export def --env 'symbols add' [] {
  let idx = $in
  $env.PKD_SYMBOL_HISTORY = (symbols|prepend $idx|uniq)
}