export def markdown-to-summary [] {
  pandoc -f gfm -t html --wrap=none
  |hxnormalize -x
  |hxunent -b
  |xmlstarlet select -t --value-of '//p[contains(., '.')][1]'
  |lines
  |each {|| str trim}
  |str join ' '
  |split row '.'
  |get 0
  |str trim
}
