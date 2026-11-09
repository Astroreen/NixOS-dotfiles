// Video run of an existing Playwright setup: copy next to the project's playwright.config.ts
// (scratch copy, never committed) and run it with NODE_OPTIONS="--require <skill>/video/preload.cjs".
// One worker so the cursor and pauses play out in order; a 1440x900 video of every test.
// The report.json in VIDEO_OUT maps each test to its video (assemble.py picks clips by folder name).
import base from './playwright.config'
import { defineConfig } from '@playwright/test'

const out = process.env.VIDEO_OUT ?? './video-artifacts'
const size = { width: 1440, height: 900 }

export default defineConfig({
  ...base,
  workers: 1,
  fullyParallel: false,
  retries: 0,
  timeout: 600_000,
  expect: { timeout: 20_000 },
  outputDir: out,
  reporter: [['list'], ['json', { outputFile: `${out}/report.json` }]],
  use: { ...base.use, viewport: size, video: { mode: 'on', size }, actionTimeout: 30_000 },
  projects: [{ name: 'chromium', use: { browserName: 'chromium', viewport: size } }],
})
