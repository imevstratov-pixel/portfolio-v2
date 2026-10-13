# portfolio-v2

Daniil Evstratov's portfolio, rebuilt on Astro: a black-and-white static site
(v1). Deployed to GitHub Pages by `.github/workflows/deploy.yml`.

```sh
npm ci
npm run dev        # http://localhost:4321/portfolio-v2/
npm run verify     # build + link check + internal-notes check
npm run shots -- --out shots/now   # screenshots at 375, 768, 1280
```

Content in `src/content` is a sanitized export and is not edited by hand.
Components, content fields, CSS classes and tools: [docs/components.md](docs/components.md).
