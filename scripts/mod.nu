use ../doc

export def build-docs [] {
  doc src:nushell use doc
  doc save DOCS.pkd

  doc use ($env.PKD_HOME|path join 'user_guide.pkd')
  doc save help/ --format 'md'
}