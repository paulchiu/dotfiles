#!/usr/bin/env python3
# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///
"""
Inject (or refresh) an in-document review/correction layer into an HTML file.

The layer lets a reader click any passage (paragraph, list item, table row,
heading) to attach a correction, jot a whole-document general note, and hit
"Copy prompt" to assemble every comment into a ready-to-paste prompt for an
agent to regenerate the file. Comments persist in the browser's localStorage.

The injected block is delimited by `<!-- RC:REVIEW-LAYER ... -->` and
`<!-- /RC:REVIEW-LAYER -->`. Running this repeatedly is idempotent: an existing
block is replaced in place (an upgrade), otherwise the block is inserted just
before the closing </body> tag.

Usage:
    uv run inject-review-layer.py --html "path/to/page.html"
    uv run inject-review-layer.py --html src.html --out annotated.html
    uv run inject-review-layer.py --html src.html --doc-path "/final/dest.html"

    # no external deps, so plain python3 also works:
    python3 inject-review-layer.py --html "path/to/page.html"

Flags:
    --html      (required) HTML file to inject into.
    --out       (optional) write result here instead of editing --html in place.
    --doc-path  (optional) absolute path embedded in the copied prompt as the
                file the agent should edit. Defaults to the absolute path of the
                final output (--out if given, else --html). Set this when the
                page will ultimately live somewhere other than where you run it.
"""

import argparse
import json
import re
import sys
from pathlib import Path

MARKER_RE = re.compile(
    r"<!--\s*RC:REVIEW-LAYER.*?/RC:REVIEW-LAYER\s*-->\s*",
    re.DOTALL | re.IGNORECASE,
)
BODY_CLOSE_RE = re.compile(r"</body\s*>", re.IGNORECASE)
PLACEHOLDER = "__RC_DOC_PATH__"


def load_template() -> str:
    """Read the review-layer template that ships alongside this script."""
    template = Path(__file__).resolve().parent.parent / "assets" / "review-layer.html"
    if not template.is_file():
        sys.exit(f"error: template not found at {template}")
    return template.read_text(encoding="utf-8")


def build_block(template: str, doc_path: str) -> str:
    """Substitute the document path into the template as a JSON-safe JS literal."""
    if PLACEHOLDER not in template:
        sys.exit(f"error: template is missing the {PLACEHOLDER} placeholder")
    # json.dumps yields a correctly quoted/escaped JS string literal.
    block = template.replace(PLACEHOLDER, json.dumps(doc_path))
    return block.rstrip("\n")


def inject(source: str, block: str) -> str:
    """Replace an existing RC block, or insert before the closing </body>."""
    if MARKER_RE.search(source):
        return MARKER_RE.sub(lambda _m: block + "\n", source, count=1)
    if BODY_CLOSE_RE.search(source):
        return BODY_CLOSE_RE.sub(lambda _m: block + "\n</body>", source, count=1)
    # No </body> (fragment or malformed doc): append at the end.
    return source.rstrip("\n") + "\n" + block + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description="Inject an HTML review/correction layer.")
    parser.add_argument("--html", required=True, help="HTML file to inject into.")
    parser.add_argument("--out", help="Output path (defaults to editing --html in place).")
    parser.add_argument("--doc-path", help="Absolute path embedded in the copied prompt.")
    args = parser.parse_args()

    src_path = Path(args.html)
    if not src_path.is_file():
        sys.exit(f"error: --html not found: {src_path}")

    out_path = Path(args.out) if args.out else src_path
    doc_path = args.doc_path or str(out_path.resolve())

    source = src_path.read_text(encoding="utf-8")
    block = build_block(load_template(), doc_path)
    result = inject(source, block)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(result, encoding="utf-8")

    action = "refreshed" if MARKER_RE.search(source) else "injected"
    print(f"{action} review layer -> {out_path.resolve()}")
    print(f"prompt targets: {doc_path}")


if __name__ == "__main__":
    main()
