"""Print the built page to a PDF with bookmarks (the contents menu of the page).

Usage (NixOS, no browser download):
  nix-shell -p 'python3.withPackages(p: [p.playwright])' chromium \
    --run 'python3 -I pdf.py <out>/index.html <out>/changes.pdf'

The bookmarks come from the headings: the title, the groups (h2) and the changes (h3).
"""
import os
import shutil
import sys

from playwright.sync_api import sync_playwright

src, dst = (os.path.abspath(p) for p in sys.argv[1:3])
chrome = os.environ.get("CHROME") or shutil.which("chromium") or shutil.which("chromium-browser")
if not chrome:
    sys.exit("no chromium on PATH: run inside nix-shell -p chromium")

with sync_playwright() as p:
    browser = p.chromium.launch(executable_path=chrome)
    page = browser.new_page(color_scheme="light")
    page.goto(f"file://{src}", wait_until="networkidle")
    # Lazy pictures below the fold never load for print; the glossary is a closed <details>.
    page.evaluate("""async () => {
      for (const d of document.querySelectorAll('details.gloss')) d.open = true;
      const imgs = [...document.querySelectorAll("main img")];
      for (const i of imgs) i.loading = 'eager';
      await Promise.all(imgs.map((i) => i.complete ? null : new Promise((r) => { i.onload = i.onerror = r })));
      await document.fonts.ready;
    }""")
    broken = page.evaluate("[...document.querySelectorAll('main img')].filter((i) => !i.naturalWidth).map((i) => i.getAttribute('src'))")
    page.emulate_media(media="print")
    page.pdf(path=dst, prefer_css_page_size=True, print_background=True, outline=True, tagged=True)
    browser.close()

print(f"{dst} ({os.path.getsize(dst) // 1024} KB)")
if broken:
    sys.exit(f"pictures that did not load: {broken}")
