export def main [name?, index?] {
  if (($name|describe) == 'int') {
    $env.PKD_CURRENT|get $name|present
  } else if ($name != null) {
    let list = $env.PKD_CURRENT|search $name

    if ($index != null) {
      $list|get $index|present
    } else {
      $list|present-list
    }
  } else {
    $env.PKD_CURRENT|present-list
  }
}

def present-list [] {
  if ($in|length) == 1 {
    $in|get 0|present
  } else {
    $in|summarize-all
  }
}

export def-env use [docs] {
  let type = $docs|describe
  if ($type == 'string') {
    $env.PKD_CURRENT = (open $docs|from yaml)
    $env.PROMPT_COMMAND_RIGHT = { $"using ($docs)" }
  } else {
    $env.PKD_CURRENT = $docs
  }
}

def search [name] {
  find $name -c ["name"]
}

def show [] {
  less -S --chop-long-lines
}

def "from pkd" [] {
  from yaml
}

def summarize [] {
  select name? kind? summary?|trim-record-whitespace
}

def summarize-all [] {
  each {|| summarize}
}

def map-record-values [block: closure] {
  items $block|reduce --fold {} {|a, b| $b|merge $a}
}

def trim-record-whitespace [] {
  map-record-values {|key, value| {
    $key: (if (($value|describe) == 'string') {
      $value|str trim
    } else {
      $value
    })
  }}
}

def html-to-md [] {
  pandoc --from=html --to=gfm-raw_html
}

def present [] {
  trim-record-whitespace
  |maybe-update type {|| str join ' -> '}
  |maybe-update parameters {|| each {|| trim-record-whitespace }}
}

def maybe-update [name, value] {
  if ($in|get -i $name) != null {
    update $name $value
  } else {
    $in
  }
}
