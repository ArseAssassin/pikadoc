def tables-query [schema:string] {
  $"SELECT * FROM information_schema.tables WHERE table_schema = '($schema)'"
}

def columns-query [schema:string, table?:string] {
  $"SELECT * FROM information_schema.columns WHERE table_schema = '($schema)'" + (
    if ($table == null) {
      ''
    } else {
      $"AND table_name = '($table)'"
    }
  )
}

def functions-query [schema:string] {
  $"SELECT * FROM pg_catalog.pg_namespace n
  JOIN
    pg_catalog.pg_proc p ON
    p.pronamespace = n.oid
  WHERE
    p.prokind = 'f'
  AND
    n.nspname = '($schema)';"
}

def type-names-query [types:list] {
  $"SELECT oid, typname FROM pg_type WHERE oid IN \(($types|str join ', ')\)"
}

def columns-get [schema:string, args:list<string>, table?:string] {
  psql -c (columns-query $schema $table) --csv ...$args
  |from csv
  |each {|row|
    let table = $"($row.table_catalog).($row.table_schema)"
    {
      ns: $table
      name: ($row.table_name + '.' + $row.column_name)
      kind: 'column'
      type: $row.data_type
      nullable: ($row.is_nullable == 'YES')
      pk: ($row.is_identity == 'YES')
      default: $row.column_default
    }
  }
}

def parse-psql-array [] {
  let array = $in
  $array
  |str substring 1..-1
  |split row ','
}

# Queries a PostgreSQL database for definitions. All tables, views and functions that can be found are mounted as a doctable.
#
# ### Examples:
# ```nushell
# # Parses database 'my_database'.'schema' for definitions
# > doc src:psql use 'public' '-d' 'my_database'
# ```
export def --env use [
  schema:string, # name of the schema to use
  ...args        # rest of the arguments are passed to psql/pg_dump as-is
  ] {
  do --env $env.DOC_USE {
    def exec-query [query:string] {
      psql -c $query --csv ...$args
    }
    let tables = (
      exec-query (tables-query $schema)
      |from csv
      |each {|row|
        let table = $"($row.table_catalog).($row.table_schema)"
        {
          ns: $table
          name: $row.table_name
          description: ("```sql\n" +
            (pg_dump -t $"($row.table_schema).($row.table_name)" --schema-only ...$args
            |lines
            |where {|row| not (
              ($row|str starts-with '--') or
              ($row|str starts-with 'SELECT ') or
              ($row|str starts-with 'SET ')
            )}
            |str join "\n"
            |str replace -a "\n\n" "\n"
            |str trim)
            + "\n```")
          kind: (match $row.table_type
            { "VIEW" => 'view',
              _ => "table" }
          )
          columns: (columns-get $schema $args $row.table_name)
        }
      }
    )

    let columns = (columns-get $schema $args)

    let functions = (
      exec-query (functions-query $schema)
      |from csv
      |each {|row|
        let argtypes = (
          (($row.proargtypes|split row ' ') ++ [$row.prorettype])
          |each {into string}
        )
        let argtypeNames = (
          $argtypes
          |uniq
          |filter {$in != ''}
          |do {
            let types = $in

            exec-query (type-names-query $types)
            |from csv
            |each {|row|
              { ($row.oid|into string): $row.typname }
            }
          }
          |reduce --fold {} {|a, b| $a|merge $b}
        )
        let argnames = (
          $row.proargnames
          |parse-psql-array
        ) ++ (0..|each {''}|take (($argtypes|length) - ($row.proargnames|length)))

        let args = (
          $argtypes|zip $argnames
          |each {|row|
            {
              name: $row.1
              type: ($argtypeNames|get -i $row.0)
            }
          }
        )

        {
          ns: $row.nspname
          name: $row.proname
          kind: 'function'
          signatures: [
            ($args|each { merge {kind: 'positional'} })
          ]
          description: ("```sql\n" + $row.prosrc + "\n```")
        }
      }
    )

    {
      about: {
        name: $"psql: ($schema) ($args|str join ' ')"
        text_format: 'markdown'
        language: 'sql'
      }
      doctable: (
        $tables ++ $columns ++ $functions
        |sort-by name
      )
    }

  }
}