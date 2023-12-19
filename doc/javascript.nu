export def parse-from-jsdoc [] {
  where undocumented? != true|each {
    |row| {
      name: ($row.longname?),
      summary: ($row.description?|default ""|split row "\n\n"|get 0?),
      returns: $row.returns?.0?.description?
      type: ($row.params?|default []|each {|param| $param.type.names|str join '|'}|append $row.returns?.0.type.names.0|str join ' -> ')
      kind: $row.kind
      source: $row.comment?
      examples: $row.examples?
      namespace: $row.memberof?
    }
  }
}