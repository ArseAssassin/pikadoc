# Copy this file to `$env.PKD_CONFIG_HOME/picadocrc.nu` to source it when starting pikadoc. Any definitions present here are made available in the shell.

# $env.PKD_CONFIG.table_max_rows = 30
#
# # Filters input to only symbols that can return values of type `$type`
# #
# # ### Examples:
# # ```nu
# # doc|where-returns 'int'
# # ```
# def where-returns [type:string] {
#   where {$in.signatures?|flatten|any {$in.kind? == 'return' and $in.type == $type}}
# }