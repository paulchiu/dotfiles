(function () {
  const LABEL_NOTE = 'Claude notes ...'
  const LABEL_REC = 'And recommends ...'

  /** Strip the uppercase block label ("Why this matters", "Recommended change") off a .why/.rec div. */
  const stripLabel = (node) => {
    const clone = node.cloneNode(true)
    const k = clone.querySelector('.k')
    if (k) k.remove()
    return clone
  }

  /** Body of a finding: everything between the source attribution and the why/rec blocks. */
  const bodyNodes = (finding) =>
    [...finding.children].filter(
      (el) =>
        !el.matches('h3, blockquote, p.src, .why, .rec, .fbbar') &&
        (el.tagName === 'P' || el.tagName === 'UL' || el.tagName === 'OL'),
    )

  /**
   * A spacer block between every part. An empty <p> is dropped by most rich-text
   * editors on paste, so the nbsp is load-bearing: it keeps the block alive and
   * renders as the blank line the comment needs.
   */
  const SPACER = '<p>&nbsp;</p>'

  const toHtml = (nodes) =>
    nodes
      .map((n) => {
        if (n.tagName === 'UL' || n.tagName === 'OL') {
          const items = [...n.querySelectorAll(':scope > li')]
            .map((li) => '<li><i>' + li.innerHTML.trim() + '</i></li>')
            .join('')
          return '<' + n.tagName.toLowerCase() + '>' + items + '</' + n.tagName.toLowerCase() + '>'
        }
        return '<p><i>' + n.innerHTML.trim() + '</i></p>'
      })
      .join(SPACER)

  /** Markdown fallback flavour: backticks for code, underscores for italics. */
  const toText = (nodes) =>
    nodes
      .map((n) => {
        const render = (el) => {
          const c = el.cloneNode(true)
          c.querySelectorAll('code').forEach((x) => x.replaceWith('`' + x.textContent + '`'))
          c.querySelectorAll('em, i').forEach((x) => x.replaceWith(x.textContent))
          return c.textContent.replace(/\s+/g, ' ').trim()
        }
        if (n.tagName === 'UL' || n.tagName === 'OL') {
          return [...n.querySelectorAll(':scope > li')].map((li) => '- _' + render(li) + '_').join('\n')
        }
        return '_' + render(n) + '_'
      })
      .join('\n\n')

  const build = (finding, includeWhy) => {
    const note = bodyNodes(finding)
    const why = finding.querySelector('.why')
    if (includeWhy && why) note.push(stripLabel(why))
    const rec = finding.querySelector('.rec')

    const htmlParts = ['<p>' + LABEL_NOTE + '</p>', toHtml(note)]
    const textParts = [LABEL_NOTE, toText(note)]

    if (rec) {
      const recNodes = [stripLabel(rec)]
      htmlParts.push('<p>' + LABEL_REC + '</p>', toHtml(recNodes))
      textParts.push(LABEL_REC, toText(recNodes))
    }
    return { html: htmlParts.join(SPACER), text: textParts.join('\n\n') }
  }

  /** Rich flavour first so Notion receives real italics and code spans; plain text is the fallback. */
  const copy = async ({ html, text }) => {
    try {
      await navigator.clipboard.write([
        new ClipboardItem({
          'text/html': new Blob([html], { type: 'text/html' }),
          'text/plain': new Blob([text], { type: 'text/plain' }),
        }),
      ])
      return true
    } catch (e) {
      try {
        await navigator.clipboard.writeText(text)
        return true
      } catch (e2) {
        const ta = document.createElement('textarea')
        ta.value = text
        ta.style.position = 'fixed'
        ta.style.opacity = '0'
        document.body.appendChild(ta)
        ta.select()
        const ok = document.execCommand('copy')
        ta.remove()
        return ok
      }
    }
  }

  const opts = document.createElement('div')
  opts.className = 'fbopts'
  opts.innerHTML =
    '<label><input type="checkbox" id="fb-why"> Include "Why this matters" in the copied text</label>' +
    '<span class="fbhint">Each finding copies as: ' + LABEL_NOTE + ' / finding in italics / ' + LABEL_REC + ' / recommendation in italics.</span>'
  const firstFinding = document.querySelector('.finding')
  firstFinding.parentNode.insertBefore(opts, firstFinding)

  document.querySelectorAll('.finding').forEach((finding) => {
    const bar = document.createElement('div')
    bar.className = 'fbbar'
    const btn = document.createElement('button')
    btn.type = 'button'
    btn.className = 'copyfb'
    btn.textContent = 'Copy feedback'
    const hint = document.createElement('span')
    hint.className = 'fbhint'
    const fid = finding.querySelector('.fid')
    hint.textContent = fid ? fid.textContent : ''
    btn.addEventListener('click', async () => {
      const ok = await copy(build(finding, document.getElementById('fb-why').checked))
      btn.textContent = ok ? 'Copied' : 'Copy failed'
      btn.classList.toggle('done', ok)
      setTimeout(() => {
        btn.textContent = 'Copy feedback'
        btn.classList.remove('done')
      }, 1600)
    })
    bar.appendChild(btn)
    bar.appendChild(hint)
    finding.appendChild(bar)
  })
})()
