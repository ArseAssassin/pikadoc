use ../doc

export def sync-devdocs [savePath:string, maxFileSize:string='1Mb'] {
  # blacklisted docs cause parser to fail
  const BLACKLIST = ['bluebird', 'date_fns', 'koa', 'spring_boot']

  let repo = doc s index|get name

  doc src:devdocs index
  |where { not ($in.name in $repo) and not ($in.slug in $BLACKLIST) }
  |uniq-by name
  |take 100
  |each {
    let slug = $in.slug
    let archive = http get $"https://downloads.devdocs.io/($slug).tar.gz"

    if (($archive|bytes length|into filesize) < ($maxFileSize|into filesize)) {
      print $"Using ($slug)"
      doc src:devdocs use $slug
      doc save $"($savePath)/(doc pkd-about|get slug).pkd"
    }
  }
}

export def build-docs [] {
  doc src:nushell use doc
  doc save DOCS.pkd

  doc use ($env.PKD_HOME|path join 'user_guide.pkd')
  doc save help/ --format 'md'
}