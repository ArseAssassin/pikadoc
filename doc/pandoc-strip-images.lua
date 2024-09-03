function Image () return {} end
function CodeBlock(it)
  if it.attributes['data-language'] ~= nil then
    it.classes = {it.attributes['data-language']}
  end
  return it
end

