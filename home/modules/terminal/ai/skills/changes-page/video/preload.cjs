// Video aid for Playwright recordings, loaded with NODE_OPTIONS="--require <this file>".
// It patches the playwright-core client, so the specs stay untouched:
// - a visible cursor (init script) that follows real mouse events, with no CSS lag;
// - before every user action: a 1 s pause, then the mouse glides to the target over ~0.8 s;
// - one more second before goto / reload / goBack / goForward, so the old page is seen leaving
//   (a click that opens a page already waited); not before a URL in VIDEO_NO_PAUSE_URLS
//   (default "/login": specs drop the session cookie first, and a wait there lets the app redirect);
// - a red click marker drawn on the real mousedown, at its coordinates, without a CSS animation;
// - a 2.5 s hold before a context closes, so the last screen of a check stays in the video.
// Env: PLAYWRIGHT_CORE_DIR (default: resolved from the current directory), VIDEO_PAUSE_MS (1000),
// VIDEO_GLIDE_MS (800), VIDEO_HOLD_MS (2500), VIDEO_NO_PAUSE_URLS (comma-separated substrings).
const path = require('path')
const core = process.env.PLAYWRIGHT_CORE_DIR
  || path.dirname(require.resolve('playwright-core/package.json', { paths: [process.cwd()] }))
const lib = path.join(core, 'lib/client')
const { BrowserContext } = require(path.join(lib, 'browserContext.js'))
const { Frame } = require(path.join(lib, 'frame.js'))
const { Page } = require(path.join(lib, 'page.js'))

const num = (v, d) => (v === undefined || v === '' ? d : Number(v))
const PAUSE = num(process.env.VIDEO_PAUSE_MS, 1000)
const GLIDE = num(process.env.VIDEO_GLIDE_MS, 800)
const HOLD = num(process.env.VIDEO_HOLD_MS, 2500)
const NO_PAUSE = (process.env.VIDEO_NO_PAUSE_URLS ?? '/login').split(',').filter(Boolean)
const STEPS = 32
const sleep = ms => new Promise(r => setTimeout(r, ms))

const CURSOR = `(() => {
  const add = () => {
    if (document.getElementById('__vcursor')) return
    const c = document.createElement('div'); c.id = '__vcursor'
    c.innerHTML = '<svg width="22" height="26" viewBox="0 0 22 26"><path d="M2 2 L2 21 L7 16.5 L10.5 24 L14 22.5 L10.6 15.2 L17.5 15.2 Z" fill="#111" stroke="#fff" stroke-width="1.6" stroke-linejoin="round"/></svg>'
    c.style.cssText = 'position:fixed;left:-50px;top:-50px;width:22px;height:26px;margin:-2px 0 0 -2px;z-index:2147483647;pointer-events:none;'
    document.documentElement.appendChild(c)
    const at = (x, y) => { c.style.left = x + 'px'; c.style.top = y + 'px' }
    window.__vset = at
    addEventListener('mousemove', e => at(e.clientX, e.clientY), true)
    addEventListener('mousedown', e => {
      at(e.clientX, e.clientY)
      const d = document.createElement('div')
      d.style.cssText = 'position:fixed;left:' + e.clientX + 'px;top:' + e.clientY + 'px;width:30px;height:30px;margin:-15px 0 0 -15px;' +
        'border-radius:50%;background:rgba(225,29,72,.45);border:3px solid #e11d48;z-index:2147483646;pointer-events:none'
      document.documentElement.appendChild(d)
      setTimeout(() => d.remove(), 700)
    }, true)
  }
  if (document.documentElement) add()
  addEventListener('DOMContentLoaded', add)
})()`

async function approach(frame, selector, opts) {
  const page = frame._page
  if (!page || (opts && opts.trial)) return
  await sleep(PAUSE)
  try {
    const loc = frame.locator(selector).first()
    await loc.waitFor({ state: 'visible', timeout: 4000 })
    await loc.scrollIntoViewIfNeeded({ timeout: 3000 })
    const b = await loc.boundingBox()
    if (!b) return
    const tx = b.x + b.width / 2, ty = b.y + b.height / 2
    const vp = page.viewportSize() || { width: 1440, height: 900 }
    const from = page.__vpos || { x: vp.width / 2, y: vp.height / 2 }
    await page.evaluate(([x, y]) => window.__vset && window.__vset(x, y), [from.x, from.y]).catch(() => {})
    for (let i = 1; i <= STEPS; i++) {
      const t = i / STEPS, e = t < .5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2
      await page.mouse.move(from.x + (tx - from.x) * e, from.y + (ty - from.y) * e)
      await sleep(GLIDE / STEPS)
    }
    page.__vpos = { x: tx, y: ty }
  } catch { /* the action itself reports what is wrong */ }
}

for (const m of ['click', 'dblclick', 'tap', 'fill', 'hover', 'selectOption', 'type', 'press', 'check', 'uncheck', 'setChecked']) {
  const orig = Frame.prototype[m]
  if (!orig) continue
  Frame.prototype[m] = async function (selector, ...a) {
    const opts = a.find(x => x && typeof x === 'object' && !Array.isArray(x))
    await approach(this, selector, opts)
    return orig.call(this, selector, ...a)
  }
}

// Page.goto goes through its main frame, so this covers both
const goto = Frame.prototype.goto
Frame.prototype.goto = async function (...a) {
  if (this._page && this._page.url() !== 'about:blank' && !NO_PAUSE.some(u => String(a[0]).includes(u))) await sleep(PAUSE)
  return goto.apply(this, a)
}
for (const m of ['reload', 'goBack', 'goForward']) {
  const orig = Page.prototype[m]
  Page.prototype[m] = async function (...a) { await sleep(PAUSE); return orig.apply(this, a) }
}

const newPage = BrowserContext.prototype.newPage
BrowserContext.prototype.newPage = async function (...a) {
  if (!this.__vcursor) { this.__vcursor = true; await this.addInitScript(CURSOR) }
  return newPage.apply(this, a)
}
const close = BrowserContext.prototype.close
BrowserContext.prototype.close = async function (...a) {
  if (this.pages().length) await sleep(HOLD)
  return close.apply(this, a)
}
