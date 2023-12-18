let TurndownService = require('turndown')
let turndownService = new TurndownService()

async function read(stream) {
  const chunks = [];
  for await (const chunk of stream) chunks.push(chunk);
  return Buffer.concat(chunks).toString('utf8');
}

async function doit() {
  let input = await read(process.stdin)
  console.log(turndownService.turndown(input))
}

turndownService.addRule('table', {
  filter: ['table'],
  replacement: (content, node, options) => {
    let normalizeCellContent = (it) => it.replace(/(\r\n|\n|\r)/gm, "").trim()

    let header = Array.from(node.querySelectorAll('th')).map((it) =>
      normalizeCellContent(it.textContent)
    )

    let rows = Array.from(node.querySelectorAll('tr')).map((it) =>
      Array.from(it.querySelectorAll('td')).map((it) =>
        normalizeCellContent(it.textContent)
      )
    ).filter((it) => it.length)

    let getColLength = (i) => {
      let cells = [header[i]].concat(rows.map((it) => it[i]))

      return Math.max(...cells.map((it) => it.length))
    }

    let formatRow = (it) =>
      '| ' + it.join(' | ') + ' |'

    Array.from({ length: header.length }, (value, index) => index)
    .forEach((i) => {
      let len = getColLength(i)

      header[i] = header[i].padEnd(len)
      rows.forEach((it) => it[i] = it[i].padEnd(len))
    })

    header = formatRow(header)
    rows = rows.map(formatRow)

    let maxLength = Math.max(header.length, ...rows.map((it) => it.length))

    return [header, '='.repeat(maxLength)].concat(rows).join('\n')
  }
})

turndownService.addRule('pre', {
  filter: ['pre'],
  replacement: (content, node, options) => {
    return '\n```\n' + content + '\n```\n\n'

  }
})

doit()
