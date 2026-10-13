// @ts-check
import { defineConfig } from 'astro/config';
import { satteri } from '@astrojs/markdown-satteri';

// Deploy target comes from the environment so the same code builds the preview
// (imevstratov-pixel.github.io/portfolio-v2/) and, later, the live site.
// This file is the only place where the default base is written down.
const SITE = process.env.SITE || 'https://imevstratov-pixel.github.io';
const RAW_BASE = process.env.BASE || '/portfolio-v2/';
const BASE = ('/' + RAW_BASE.replace(/^\/+|\/+$/g, '') + '/').replace(/\/+/g, '/');

export default defineConfig({
  site: SITE,
  base: BASE,
  output: 'static',
  trailingSlash: 'ignore',
  build: { format: 'directory' },
  devToolbar: { enabled: false },
  markdown: {
    syntaxHighlight: false,
    // Approved texts already carry their own typography («», —, non-breaking
    // spaces). Smart punctuation would rewrite quotes and dashes, so it is off.
    processor: satteri({ features: { smartPunctuation: false } }),
  },
});
