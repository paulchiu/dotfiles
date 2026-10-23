"""Render a Feedback Friday suggestions .md into the sandbox house HTML layout.

Usage: python3 -I md2html.py <in.md> <out.html>
Header fields come from the front matter keys title, eyebrow, subtitle and meta
(meta items separated by " · "). The raw front matter is copied into the
reproducibility comment after the doctype, per the dated-doc convention.
"""
import html
import os
import re
import sys

src, out = sys.argv[1], sys.argv[2]
text = open(src).read()
fm_end = text.index("\n---\n", 4)
front = text[4:fm_end]
body = text[fm_end + 5:].strip("\n").split("\n")


def fm(key):
    m = re.search(rf'^{key}:\s*"?(.*?)"?\s*$', front, re.M)
    return m.group(1) if m else ""


footnotes = {}
lines = []
for ln in body:
    m = re.match(r"\[\^(\d+)\]: (.*)", ln)
    if m:
        footnotes[int(m.group(1))] = m.group(2)
    else:
        lines.append(ln)

URL = re.compile(r"(https?://[^\s)]+)")


def inline(s):
    s = html.escape(s, quote=False)
    s = re.sub(r"`([^`]+)`", lambda m: "<code>" + m.group(1).replace("\\|", "|") + "</code>", s)
    s = s.replace("\\|", "|")
    s = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", s)
    s = re.sub(r"\[\^(\d+)\]", r'<sup><a href="#fn-\1">\1</a></sup>', s)
    s = URL.sub(lambda m: f'<a href="{m.group(1)}">{m.group(1)}</a>', s)
    return s


def table(rows):
    cells = [[c.strip() for c in r.strip().strip("|").split(" | ")] for r in rows]
    head, data = cells[0], cells[2:]
    h = "".join(f"<th>{inline(c)}</th>" for c in head)
    b = "".join("<tr>" + "".join(f"<td>{inline(c)}</td>" for c in r) + "</tr>" for r in data)
    return f'<div class="tablewrap"><table><thead><tr>{h}</tr></thead><tbody>{b}</tbody></table></div>'


def draft(qlines):
    paras, srcs = [], []
    for q in qlines:
        q = q[1:].strip()
        if not q:
            continue
        (srcs if re.match(r"\[\d+\]:", q) else paras).append(q)
    plain = "\n\n".join(paras) + ("\n\n" + "\n".join(srcs) if srcs else "")
    ps = "".join(f"<p>{inline(p)}</p>" for p in paras)
    ss = "".join(f"<li>{inline(s)}</li>" for s in srcs)
    return (
        '<div class="draft"><div class="draft-head"><span class="k">Draft in Paul\'s voice</span>'
        f'<button type="button" class="copy" data-text="{html.escape(plain)}">Copy</button></div>'
        f"{ps}" + (f'<ul class="draft-src">{ss}</ul>' if ss else "") + "</div>"
    )


title = lines[0][2:]
i, intro = 1, []
while i < len(lines) and not lines[i].startswith("## "):
    if lines[i].strip():
        intro.append(f"<p>{inline(lines[i])}</p>")
    i += 1

parts, in_section = [], False
while i < len(lines):
    ln = lines[i]
    if ln.startswith("## "):
        if in_section:
            parts.append("</section>")
        in_section = ln[3:] != "Sources"
        if in_section:
            parts.append(f'<section id="s{len(parts)}"><h2>{inline(ln[3:])}</h2>')
        i += 1
    elif ln.startswith("### "):
        parts.append(f"<h3>{inline(ln[4:])}</h3>")
        i += 1
    elif ln.startswith("|"):
        rows = []
        while i < len(lines) and lines[i].startswith("|"):
            rows.append(lines[i])
            i += 1
        parts.append(table(rows))
    elif ln.startswith(">"):
        q = []
        while i < len(lines) and lines[i].startswith(">"):
            q.append(lines[i])
            i += 1
        parts.append(draft(q))
    elif ln.startswith("- "):
        items = []
        while i < len(lines) and lines[i].startswith("- "):
            items.append(f"<li>{inline(lines[i][2:])}</li>")
            i += 1
        parts.append("<ul>" + "".join(items) + "</ul>")
    elif ln.strip():
        parts.append(f"<p>{inline(ln)}</p>")
        i += 1
    else:
        i += 1
if in_section:
    parts.append("</section>")

fn = "".join(f'<li id="fn-{n}">{inline(footnotes[n])}</li>' for n in sorted(footnotes))
parts.append(f'<section id="sources"><h2>Sources</h2><ol class="fn">{fn}</ol></section>')

css = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "house.css")).read()
meta = "".join(f"<span>{html.escape(m)}</span>" for m in fm("meta").split(" · ") if m)
doc = f"""<!doctype html>
<!--
{front.replace("--", "-")}
-->
<html lang="en-AU">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(title)}</title>
<style>
{css}
</style>
</head>
<body>
<div class="wrap">
<header class="doc">
<div class="eyebrow">{html.escape(fm("eyebrow"))}</div>
<h1>{html.escape(title)}</h1>
<p class="subtitle">{html.escape(fm("subtitle"))}</p>
<div class="meta">{meta}</div>
</header>
<div class="intro">{"".join(intro)}</div>
{"".join(parts)}
</div>
<script>
document.querySelectorAll('button.copy').forEach(function (b) {{
  b.addEventListener('click', function (e) {{
    e.stopPropagation();
    try {{
      navigator.clipboard.writeText(b.getAttribute('data-text')).then(function () {{
        b.textContent = 'Copied';
        setTimeout(function () {{ b.textContent = 'Copy'; }}, 1500);
      }});
    }} catch (err) {{ console.log('copy failed', err); }}
  }});
}});
</script>
</body>
</html>
"""
open(out, "w").write(doc)
print("ok", len(footnotes), "footnotes")
