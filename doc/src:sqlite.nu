# Returns documentation for all tables, columns and indexes in a sqlite database.
#
# `in` is a valid sqlite database.
#
# Example: open my-database.db|doc src:sqlite parse-from-db
export def parse-from-db [] {
  let $db = $in
  let tables = $db|query db 'SELECT type, name, sql FROM sqlite_master WHERE name not like "sqlite_%"'

  $tables|each {|tbl| {
    name: $tbl.name
    columns:
      ($db
        |query db $"PRAGMA table_info\(($tbl.name)\)"
        |each {|col| {
          name: $col.name
          type: $col.type
          defaultValue: $col.dflt_value
          nullable: ($col.notnull == 0)
          pk: ($col.pk == 1)
        }})
    source: $tbl.sql
    kind: (if ($tbl.type == 'index') { 'index' } else { 'table' })
  }}
}

# Queries a sqlite database for its tables and selects the output as the current doctable
#
# `db` is a path to your sqlite database
#
# Example: doc src:sqlite use ./my-database.db
export def --env use [db] {
  $env.PKD_CURRENT = (open $db|parse-from-db)
  $env.PKD_ABOUT = {
    name: $db
    text_format: 'text'
    generator: 'src:sqlite'
  }
}