export def generate-docs [] {
  use ../doc
  doc src:nushell use doc
  doc save reference-docs.pkd
}
