# Components and content: reference for page builders

Everything a page needs is described here: commands, the content each page reads,
the helpers, the shared components and the CSS classes. Build pages only from
these pieces; add a new shared piece here when two pages need it.

Stack: Astro 7.3.8 (static output), no UI framework, TypeScript in components,
fonts from @fontsource (Inter Tight 400/700, IBM Plex Mono 400, Latin and
Cyrillic subsets). One small client script (Telegram copy and analytics goals).

## 1. Rules that every page follows

- **Content only from `src/content`.** It is the sanitized export; never edit it by
  hand and never type visitor-facing text into a page. Re-export with
  `SITE_CONTENT=<path to site-content> npm run content` (runs
  `export_public.py`). Labels that the texts renderer adds itself (for example
  «Срок:» before a service duration) are the only exceptions, and they are
  already built into the components.
- **Do not rewrite texts.** Show them exactly as in the content, including
  non-breaking spaces, «», — and the double space in the mother's quote. Smart
  punctuation is off in the markdown pipeline.
- **No hard-coded base path.** Every internal link and asset goes through
  `url()` (section 3). Components that take an `href` or `src` call `url()`
  themselves, so pass content paths as they are (`/services/#audit`,
  `assets/portrait.jpg`). `url()` is idempotent.
- **Black and white.** Use only the tokens (`--ink`, `--paper`, `--muted`,
  `--rule`). No other colours, no rounded corners, shadows, gradients,
  transitions, animations or hover effects beyond underline and button
  inversion. Colour exists only inside media.
- **No arrows and no middle dots** anywhere (buttons, labels, lists): use a dash,
  «и», a comma or a step number.
- **The output must pass `npm run leakcheck`.** It greps the built site for
  `hidden`, `_note`, `_todo`, `_draft` and a few slugs. So never use these
  substrings in class names, ids or attributes: no `aria-hidden`, no `hidden`
  attribute, no `overflow: hidden` (use `overflow: clip`), no BEM elements
  like `__note` or `__notes` (use `__foot`, `__lines`). `.sr-only` exists for
  screen-reader text.
- **One `<h1>` per page.** Section headings are `h2`, items inside `h3`.
- **Anchors.** Every block with `anchor` in the content must render that id
  (`contact`, `formats`, `faq`, `numbers`, `experience`, …). Services use their
  `anchor` (`consulting`, `pipeline`, `audit`, `course`, `app`, `game`,
  `guide`) on /services/, cases their `anchor` (`case-…`) on /cases/, products
  their `anchor` on /products/. Other pages link to these; `check-links` fails
  when one is missing.
- **Images and video.** Fixed aspect ratios (component `Media`), lazy below the
  fold, alt text from the content. Video: native player, `preload="none"`,
  poster, no autoplay, no loop. The `loop` fields in the content are not used.
- **Empty means absent.** A block, line or media item without content is not
  rendered (no placeholders). `Media` renders nothing for `src: ''`.

## 2. Commands

| Command | What it does |
| --- | --- |
| `npm run dev` | Dev server at `http://localhost:4321/portfolio-v2/` |
| `npm run build` | Static build into `dist/` |
| `npm run preview` | Serves `dist/` (Astro 7 may start it in the background; stop with `npx astro preview stop`) |
| `npm run check` | `astro check`: TypeScript and template types (0 errors expected) |
| `npm run check-links` | Every internal href/src/poster in `dist/` resolves, every `#anchor` exists on its page, no link leaves the base, no `/portfolio-v2/` literal in `src/` |
| `npm run leakcheck` | Greps `dist/` for internal markers (see rules). Legacy files copied from the old site are reported, not failed, for `hidden`/`_note`; `--strict` fails on them too |
| `npm run shots -- --out shots/x / /services/` | Full-page screenshots at 375, 768, 1280 (`--widths 360,375` to change), reports horizontal overflow. Uses `/opt/pw-browsers/chromium` (override with `CHROMIUM_PATH`) and its own static server under the base path |
| `npm run verify` | build, check-links, leakcheck |
| `npm run content` | Re-run the content export (needs `SITE_CONTENT`) |

Environment: `BASE` (default `/portfolio-v2/`), `SITE` (default
`https://imevstratov-pixel.github.io`), `PREVIEW` (on unless `0`). In preview
every page has `noindex,nofollow` and no analytics; with `PREVIEW=0` the Yandex
Metrika counter 111316684 is added and `<html data-metrika>` enables goals.
Test another base with `BASE=/x/ npm run build && BASE=/x/ npm run check-links`.

## 3. Helpers (`src/lib`)

### `url.ts`

```ts
import { url, absoluteUrl, anchor, isExternal, BASE } from '../lib/url';
url('/services/#audit')   // '<base>/services/#audit'
url('assets/og.jpg')      // '<base>/assets/og.jpg'
url('/demo/wishlist/')    // '<base>/demo/wishlist/'
url('#contact')           // '#contact' (same page)
url('https://t.me/x')     // unchanged; also mailto:, tel:, data:
absoluteUrl('/services/', Astro.site) // full URL for canonical / OG
anchor('contact')         // '#contact'
```

### `content.ts`

```ts
import {
  site, getPage, pageBlocks, getBlock, findBlock, gref, workloadLine, visible, isHidden,
  services, getService, serviceByCodeword, serviceHref,
  cases, getCase, isPublished, publishedCases, caseHref, caseService, caseLabels, CASE_LABEL_FIELDS,
  products, getProduct, isProductVisible, visibleProducts, productHref, productTemplate,
  getTestimonial, testimonialSignature,
  telegramButton, telegramUrl, singleHint, mailtoHref,
  bodyHtml, bodySections,
} from '../lib/content';
```

- `site`: data of `site/global.md` (section 5.2).
- `getPage(id)`: data of `pages/<id>.md`; ids `home`, `services`, `cases`,
  `products`, `hire`, `guide`, `404`. `pageBlocks(page)` returns the visible
  blocks in order; `getBlock(page, 'hero')` one block by id (throws if
  missing), `findBlock` the same but returns `undefined`.
- `gref('global.email.line')` resolves a global reference (used in contact
  blocks: `hint`, `email`, `lines`, `workload`, terms `source`); other values
  pass through. `workloadLine(ref)` returns the workload text or `null`.
- `visible(list)` drops items with `status: 'hidden'` (the export already did;
  use it anyway for FAQ items, rows, notes, as the renderer does).
- Services: `services` (all, by `order`), `getService('audit')`,
  `serviceByCodeword('Аудит')`, `serviceHref(slugOrEntry)` gives
  `<base>/services/#<anchor>`.
- Cases: `cases` (published, by `order`, the order of /cases/),
  `getCase(slug)`, `isPublished(slug)`, `publishedCases(slugs)` keeps only
  published ones, `caseHref(c)` gives `<base>/cases/#<anchor>`,
  `caseService(c)` the service entry of a case (cases store a codeword),
  `caseLabels(c, fields)` the non-empty label values.
- Products: `products` (visible, by `order`), `getProduct`,
  `visibleProducts(slugs)`, `productHref`, `productTemplate(p)` the message
  of the quiet link (global product template with the title, or the
  product's own).
- Testimonials: `getTestimonial(slug)`, `testimonialSignature(t, extra)` builds
  «Лиза, методист, Eduson Academy» and appends extra parts (hire: company,
  relation) when new and non-empty.
- Telegram and mail: `telegramButton(codeword)` returns
  `{ codeword, caption, template, service? }`; `telegramUrl`;
  `singleHint(codeword)`; `mailtoHref({ codeword, template })` or
  `mailtoHref({ subject })` or `mailtoHref()` (default subject «Сообщение с
  сайта»).
- Markdown bodies: entries carry rendered HTML. `bodyHtml(entry)` returns it;
  `bodySections(entry, only?)` splits it at `## ` headings into
  `[{ title, html }]` without the `h2` tags (so 18 cases on one page do not
  repeat ids). Example:
  `bodySections(c, ['Контекст', 'Что сделал', 'Результат'])` for /hire/.

The module validates cross-references when it loads: unknown case, service,
product or testimonial slugs, unknown Telegram codewords and duplicate anchors
fail the build with a list of problems.

### `media.ts`

`imageSize('assets/portrait.jpg')` returns `{ width, height }` read from the
file in `public/` (JPEG, PNG, GIF, WebP); `publicFileExists(path)`. `Media`
uses them for `width`/`height` and the default ratio.

### `types.ts`

`HeaderData`, `NavLink`, `NumberItem` (`{ value, label, source? }`), `FaqItem`
(`{ q, a }`).

### `env.ts`

`PREVIEW` (boolean), `METRIKA_ID`. Only `BaseLayout` needs them.

## 4. Layout and components (`src/layouts`, `src/components`)

All components are `.astro` files. Paths in examples are from a page in
`src/pages/<route>/index.astro` (use `../../`) or `src/pages/index.astro` (`../`).

### BaseLayout

```astro
<BaseLayout page={page} current="/services/">…</BaseLayout>
```

Props: `page` (from `getPage`; gives title, description, OG image and an
optional `header` override), `title`, `description`, `ogImage`, `noindex`
(overrides), `header` (full override), `current` (site path for
`aria-current` in header and footer), `ctaHref` (target of «Написать»;
default `page.header.ctaTarget` or `#contact`). Renders `<html lang="ru">`,
head (title, description, canonical, OG with absolute image URL and size,
robots in preview and for `seo.noindex`, fonts, Metrika in production),
`Header`, `<main id="main">`, `Footer`, the client script.
/hire/ passes its page and gets its own header automatically (`pages/hire.md
header`). The 404 page passes `ctaHref="/#contact"`. If `seo.ogImage` does not
exist in `public/` (guide's `assets/og-guide.jpg` today), the site image is
used.

### Header, Footer

Used by `BaseLayout`; pages do not include them. Header: name (home link),
page links, «Написать» (primary small button). Sticky first row; on phones the
links form a second row that scrolls away. Footer: Telegram and email as text,
all footer links (incl. «Работодателям» with goal `hire`, «English» to `/en/`),
«Сделано вместе с Claude», «© {year} Даниил Евстратов».

### Section

```astro
<Section id="faq" heading={faq.heading}>…</Section>
<Section rule="none" pad="s4"><h1>…</h1></Section>
<Section id="numbers" label="Цифры" heading={b.heading} level={2} size="large" wrap={false}>…</Section>
```

Props: `id` (anchor; adds `aria-labelledby` to `<id>-heading`), `label`
(small mono line above), `heading`, `level` (2 or 3), `size` (`huge`, `large`,
`medium`), `rule` (`line` ink 1px on top, default; `hair` grey; `none`), `pad`
(space above: `s3`, `s4`, `s5` default), `wrap` (content inside `.wrap`,
default true), `class`. Slots: default, `head` (extra content under the
heading). Spacing: `pad` above the rule, `--s2` under it, `--s4` under the
heading.

### Prose

```astro
<Prose html={bodyHtml(product)} />
{bodySections(c).map((s) => (<><h3 class="label">{s.title}</h3><Prose html={s.html} /></>))}
<Prose size="medium"><p>{text}</p></Prose>
```

Props: `html` (rendered HTML) or slot, `measure` (max 66ch, default true),
`size` (`base` or `medium`), `class`. Styles for lists, blockquotes
(`white-space: pre-wrap` keeps quoted texts exact) and headings inside live in
`global.css` (`.prose`).

### Button

```astro
<Button href={hero.button.href} variant="primary" goal="telegram">{hero.button.label}</Button>
<Button href="/cases/">{b.allLink.label}</Button>
<Button href={product.data.action.url} goal="product">{product.data.action.label}</Button>
```

Props: `href` (content path or external; no href renders a `<button>`),
`variant` (`primary` ink fill, `secondary` frame; default secondary), `size`
(`base`, `small`), `block` (full width), `newTab` (default: true for http(s)
links), `goal` (analytics goal), `type`, `class`, any other attribute.

### TelegramButton

```astro
<TelegramButton codeword="Аудит" />                       <!-- word + caption, copies the template -->
<TelegramButton codeword="Аудит" variant="primary" />
<TelegramButton codeword="Вакансия" label="Обсудить роль" caption="в Telegram" variant="primary" />
<TelegramButton codeword={p.data.codeword} template={productTemplate(p)}
  label={p.data.messageLink.label} variant="link" goal="product" />  <!-- quiet product link -->
```

Props: `codeword` (from `site.telegram.buttons`; for product codewords pass
`template`), `template` (override), `caption` (override, `false` hides),
`label` (main text, default the codeword), `variant` (`primary`, `secondary`
default, `link` for a text link), `size`, `block`, `goal` (default
`telegram`), `class`. Opens `https://t.me/evstratovdanil` in a new tab; with
JS it first copies the template and shows «Скопировал, вставьте в чат» for
`copiedMs`. The home hero button and the footer link only open the chat: use
`Button` with `href={site.contacts.telegram.url}` there.

### EmailLine

```astro
<EmailLine />                                   <!-- «Или напишите на почту: imevstratov@gmail.com» -->
<EmailLine codeword="Курс" template={telegramButton('Курс').template} />
<EmailLine line={hero.email} />                 <!-- just the address -->
```

Props: `line` (text or global reference; default `global.email.line`),
`codeword`, `template`, `subject`, `size` (`base`, `medium`, `small`),
`class`. The address inside the line becomes a `mailto:` link with the
codeword as subject and the template as body (goal `email`).

### TelegramAction

```astro
<TelegramAction codeword={service.data.codeword} />
<TelegramAction codeword="Гайд" variant="primary" />
```

One button, the single-button hint («Нажмите, и начало сообщения
скопируется… начните со слова «Курс».») and the email line. Props:
`codeword`, `template`, `label`, `caption`, `variant` (default `primary`),
`hint` (default true), `email` (line, global ref or `false`), `subject`,
`class`. Use it for each service on /services/ and the /guide/ hero.

### ContactBlock

```astro
<ContactBlock block={getBlock(page, 'contact')} />   <!-- home, services, cases, guide, hire -->
<ContactBlock block={getBlock(page, 'custom')} />    <!-- products (type cta-line) -->
```

Takes the page block as is and renders it inside a `Section` with its
`anchor` (default `contact`). Variants by content:
- `buttons: [codewords]`: hint above, grid of Telegram buttons (2 columns on
  phones, 4 from 720px), email line (medium size), workload, lines;
- `button: { codeword, hint }` (guide): one primary button, its hint, email
  line, lines;
- `button: { codeword, label, caption }` + `email: { text, subject }` (hire):
  primary Telegram button and the email as a second button, `telegramText`,
  `resumes` links with their meta;
- `links` (products): a comma list of links under the text.
Props: `block`, `size` (`large` default, `huge`), `rule`, `class`.
On the home page the block shows the workload line; the texts renderer
describes the other pages' blocks as «как на главной», and the content of
those blocks already carries the same fields.

### Steps

```astro
<Section id="how-we-start"><Steps showConsultationNote={b.showConsultationNote}
  showPrepare={b.showPrepare} showWorkload={b.showWorkload} /></Section>
<Steps heading={false} level={3} showConsultationNote={false} showPrepare showWorkload={false} />
```

«Что будет после вашего сообщения» from `site.work.howWeStart`: heading, four
steps (large mono numbers from a CSS counter, «**Вы пишете.** text»), then the
optional lines. Props: `heading` (bool), `level` (2 or 3), the three `show…`
flags (take them from the block: home `steps`, services `formats.howWeStart`),
`class`.

### Numbers

```astro
<Numbers items={hero.numbers} note={hero.numbersNote} />
<Numbers items={b.items} note={b.note} columns={3} />   <!-- /hire/, 6 items -->
```

Value in large mono, label, small source, note line. 2 per row on phones;
`columns={4}`: 2 from 720px, 4 from 1080px; `columns={3}`: 3 from 720px.

### Quote

```astro
<Quote text={q.text} cite={q.attribution} size="medium" />
```

Props: `text`, `cite`, `size` (`large` default, `medium`, `base`), `marks`
(«» added by CSS, default true), `class`. Keeps the text's spacing exactly.

### VideoTestimonial

```astro
<VideoTestimonial testimonial="evgenia" />
<VideoTestimonial testimonial={it.testimonial} extra={[it.company, it.relation]} />
```

Poster in the native player (9:16) and the quote beside it with the
signature. Use it at the full container width: video 3 of 12 columns, quote 6
of 12; on phones 2 + 2 of 4. Props: `testimonial` (slug or entry), `extra`,
`quote` (default true), `class`.

### Media

```astro
<Media src="assets/portrait.jpg" alt={about.portraitAlt} ratio="1 / 1" loading="eager" />
<Media type="video" src={reel.video} poster={reel.poster} ratio="9 / 16" label={reel.hook} />
<Media src={p.data.media.src} alt={p.data.media.alt} maxWidth="20rem" />
```

Props: `src` (content path; empty renders nothing), `type` (`image` or
`video`, guessed from the extension), `alt`, `poster`, `label` (accessible
name of a video), `ratio` (CSS ratio; default the file's own), `fit`
(`cover` default, `contain`), `loading` (`lazy` default, `eager` above the
fold), `maxWidth`, `class`. Ratios: reels and testimonials `9 / 16`; product
screenshots are phone screens (554×1220 and 536×1170), use their own ratio.

### CaseLabels, CaseCard

```astro
<CaseLabels case={c} />                                  <!-- «В штате, EdTech, …, 2025–2026, Мост, **в работе**» -->
<CaseCard case={it.case} line={it.line} linkLabel={b.cardLink} title="title" />
<CaseCard case="staff-c2" linkLabel="Читать кейс" service labels={false} />
```

CaseLabels props: `case`, `fields` (default origin, industry, year, duration,
direction), `status` (default true), `class`. CaseCard props: `case`, `line`,
`linkLabel` (no link when omitted; the link goes to `/cases/#<anchor>`),
`title` (`shortTitle` default or `title`; the home featured cards use
`title`), `labels` (fields or `false`; default origin, industry, year,
direction, as on the home page), `service` (show the service short name),
`level`, `class`. Cards have a hairline on top; put them in `.cols.cols-2`.

### ServiceRow

```astro
<ul class="list-rules" role="list">
  {b.main.map((it) => <ServiceRow service={it.service} line={it.line} linkLabel={b.linkLabel} duration={b.showDuration} />)}
</ul>
<ul class="list-rules" role="list">
  {b.more.map((it) => <ServiceRow service={it.service} line={it.line} linkLabel={b.linkLabel} href={it.href} duration={b.showDuration} size="small" />)}
</ul>
```

An `<li>`: title (full `title`, bold), «Срок: …» (when `duration`), line,
link (`href` override from the content, default `/services/#anchor`). From
720px title on 5 columns and the rest on 7. Props: `service`, `line`,
`linkLabel`, `href`, `duration`, `size` (`large`, `small`), `title`
(`title` or `short`), `level`.

### ServiceCard

```astro
<ServiceCard service="guide" labels={page.serviceTemplate.labels} />
```

The short service variant (group «Мост» on /services/): title, summary, «Для
кого», «Что получите на руки», `more` link, price line, `TelegramAction`.
Carries the service anchor as id. Props: `service`, `labels`, `number`
(optional «07» label), `id` (`false` for none), `level`, `class`. The full
service template is built by the services page from the same fields
(section 5.3).

### FAQ

```astro
<Section id={faq.anchor} heading={faq.heading}><FAQ items={faq.items} /></Section>
```

`<details>/<summary>` per item, «+»/«−» marker, hairlines, no animation, no
script. Props: `items` (`{ q, a }`, hidden and empty ones are skipped), `open`,
`class`.

## 5. Content structure

Collections are defined in `src/content.config.ts` (glob loader, ids = file
names). Typed fields below; unknown extra fields are kept.

### 5.1 pages (`getPage(id)`)

Every page: `seo { title, description, ogImage?, noindex? }`, `blocks[]`
(`{ id, type, anchor?, … }`), optional `header`. Blocks per page:

**home**
- `hero` (hero): `name`, `role`, `headline` (the h1), `lead`, `button { label, href }` (plain chat link), `email`, `availability`, `numbers[{ value, label, source }]`, `numbersNote`
- `clients` (names): `lines[{ label, names[], note? }]`, `link { label, case }` (to `caseHref`)
- `services` (services): `heading`, `lead`, `showDuration`, `main[{ service, line }]`, `moreHeading`, `more[{ service, line, href? }]`, `linkLabel`
- `reels` (reels): `heading`, `hint`, `linkLabel`, `items[{ case, video, loop, poster, hook }]` (use `video` + `poster`; `.scroll-row`)
- `featured-cases` (cases): `heading`, `cardLink`, `items[{ case, line }]`, `fallback[]`, `returnLine { text, cases[] }` (show only when all its cases are published), `allLink { label, href }`
- `how-we-start` (steps): `source`, `showConsultationNote`, `showPrepare`, `showWorkload` (component `Steps`)
- `testimonials` (testimonials): `heading`, `headingColleaguesOnly`, `clients.items[]` (empty now, so the heading is `headingColleaguesOnly`), `colleagues { caption, hint, items[] }`
- `about` (about): `heading`, `portrait`, `portraitAlt`, `text[]`, `experience[{ years, place, role, note }]`, `experienceLink { label, href }` (`/hire/#experience`), `productsLine { text, linkLabel, href }`
- `contact` (contact): `anchor`, `heading`, `hint`, `buttons[]`, `email`, `lines[]`, `workload`

**services**: `serviceTemplate { labels { forWhom, youGet, duration, steps, fromYou, notIncluded, ai, proof, proofLinks, proofCasesBuilt, proofProducts, testimonials, readCase, more }, button { source, hint, email } }`
- `intro` (intro): `heading` (h1), `lead[]`, `toc.items[]` (service slugs, show `short`), `other { text, button }` (codeword «Другое»)
- `group-learning`, `group-development`, `group-bridge` (service-group): `heading`, `lead?`, `note? { text, links[{ label, service | case }] }`, `services[]`, `variant?` (`short` → `ServiceCard`)
- `formats` (formats, anchor `formats`): `heading`, `howWeStart { showConsultationNote, showPrepare, showWorkload }`, `pricing { heading, items[{ title, points[] }] }`, `predictable { heading, items[{ title, text }] }`, `terms { heading, items[{ id, text } | { id, source }] }` (`gref(source)`)
- `faq` (faq): `anchor`, `heading`, `items[{ q, a }]`
- `contact`

**cases**
- `intro`: `heading` (h1), `lead`
- `toc` (cases-toc): `heading`, `groups[{ service, products? }]` (rows: published cases whose `service` codeword matches; skip empty groups), `row.fields` (`shortTitle, industry, duration`), `productRow { labels[], hrefPattern }` (`/products/#{anchor}`), `legend { origin, direction }`
- `cases` (cases-list): `sort`, `sections[]` (the four h2 sections), `labels[]` (label fields), `statusField`, `serviceLinkLabel` («Что из этого сделаю для вас»: link to the case's service, `serviceHref(caseService(c))`)
- `contact`

**products**
- `intro`: `heading` (h1), `lead[]`
- `products`: `items[]` (product slugs, `visibleProducts`), `labels { inside, status, platform }`
- `custom` (cta-line, anchor `contact`): `heading`, `text`, `links[{ label, service, href }]`, `buttons[]`, `hint`, `email`, `lines[]`

**guide** (`header.ctaTarget: '#contact'`)
- `hero`: `heading` (h1), `lead`, `button { codeword, hint }`, `email`, `price`, `media` (pending)
- `recognize`: `heading`, `scenes[]`, `story { heading, case, text[] }`, `quote { text, attribution }`, `task { caption, source, instruction, prompt, notice, media }`, `demo { label, url, note, tryFirst }`
- `included`, `safety` (numbered): `heading`, `lead?`, `items[{ title, text }]`, `notes[]`
- `faq`, `about` (`heading`, `portrait`, `portraitAlt`, `text[]`, `link { label, href }`), `contact` (single button)

**hire** (own `header { name, links, cta }`)
- `hero` (hire-hero): `name` (h1), `role`, `lead[]`, `portrait`, `portraitAlt`, `button { codeword, label, caption }`, `email { text, subject }`, `resumes[{ label, meta, href }]`
- `facts`: `anchor`, `heading`, `rows[{ label, value, extra?[], links?[{ label, url }] }]`
- `numbers`: `anchor`, `heading`, `items[]`, `note`
- `experience`: `anchor`, `heading`, `lead`, `caseDisplay { sections[], showReel, … }`, `items[{ id, dates, duration?, role, place, placeFull?, placeNote?, about, results?[], stack?, cases?[{ case, show: 'line' | 'full', links?, scheme? }] }]` (`line` shows `case.hire.line`; `full` shows the case sections without labels and without the service line)
- `testimonials`: `anchor`, `heading`, `hint`, `items[{ testimonial, company, relation }]`
- `team` (columns): `anchor`, `heading`, `columns[{ title, text, link? { label, url } }]`, `process { heading, items[] }`
- `contact`: `button { codeword, label, caption }`, `email { text, subject }`, `telegramText`, `resumes[]`

**404**: `not-found`: `code`, `heading` (h1), `text`, `button { label, href }`, `links[{ label, href }]`

### 5.2 site (`site`)

`site { name, lang, ogImage }`, `contacts { telegram { handle, url, text }, email }`,
`header { name, links[], cta }`, `footer { contacts { telegramLabel, telegramText, emailLabel, emailText }, links[], madeWith, copyright }`,
`telegram { plainButton, copiedLabel, copiedMs, singleHint, gridHint, buttons[{ codeword, caption, template, service? }], productTemplate }`,
`email { line, short, mailto { subject, body }, defaultSubject }`,
`work { howWeStart { heading, steps[{ title, text }], consultationNote, prepare, workload { text } }, price, payment, languages }`.

### 5.3 services (7, `services`)

`title`, `short`, `codeword`, `anchor`, `line` (Обучение, Разработка, Мост),
`order`, `summary`, `forWhom[]`, `youGet[]`, `duration`, `durationNote?`,
`steps[]`, `fromYou?`, `ai?`, `notIncluded[]`, `proofCases[]`,
`proofNotes? { caseSlug: note }`, `proofLinks?[{ label, url, note?, case?, product? }]`,
`proofProducts?[]`, `testimonials?[]`, `more? { label, url }`,
`related? { text, service?, case? }`, `price`; body: one paragraph
(`bodyHtml`). Full template order (render_service): body, «Для кого»,
«Что получите на руки», «Сколько длится» (`duration + '. ' + durationNote`),
«Как идёт работа» (numbered), «Что нужно от вас», «Что не входит»,
«Нейросеть и расходы» (`ai`), proof: for `app` first «Что можно открыть»
(`proofLinks`) then «Что я написал сам» (`proofCases`); for others «Чем
подтверждено» (published `proofCases` with notes, then `proofLinks`), then
«Мои продукты» (visible `proofProducts`: title and `oneLiner`); «Что говорят
коллеги» (`testimonials`); `price + '.'`; `TelegramAction`.

### 5.4 cases (18 published, `cases`)

`title`, `shortTitle`, `origin`, `industry`, `year`, `duration?`, `direction`,
`service` (codeword), `anchor`, `status?` («в работе»), `featured`, `order`,
`published`, `hire? { place, line? }`, `links?[{ label, url, note? }]`,
`reel? { video, loop, poster }`, `scheme? { heading, person, steps[{ n, title, text, repair?, check? }], base, facts[] }`
(staff-c2 only, «Как устроен конвейер»: the `person` line above the
numbered steps, each step «**title.** text.» plus `repair` and `check`, the
`base` line under them, `facts` as a comma list; no arrows), `testimonials?[]`. Body sections: «Контекст», «Что
сделал», «Результат», «Что из этого сделаю для вас» (`bodySections`).

### 5.5 products (5, `products`)

`title`, `anchor`, `codeword`, `kind`, `status`, `platform`, `oneLiner`,
`inside`, `statusNote?`, `visible`, `action? { label, url }` (no action means
no button: the two party games), `secondaryLinks?[{ label, url, note? }]`,
`media { type, src, alt, status }` (src `''` while pending; Top Pick and ДОБЕЙ
have screenshots under `/products/`), `messageLink { label, template }`
(`productTemplate(p)`), `metrics[]`, `order`; body paragraphs (`bodyHtml`).
Product names use the huge size.

### 5.6 testimonials (5)

`name`, `role`, `company` (may be ''), `kind` (`video`), `video`, `loop`,
`poster`, `quote`, `pages[]`. Use `VideoTestimonial`.

## 6. CSS (`src/styles`)

`tokens.css` (custom properties) and `global.css` (reset, type, links, focus,
buttons, rules, grid, utilities) load in `BaseLayout`. Components keep their
own scoped styles.

**Tokens.** Colour `--ink #000`, `--paper #fff`, `--muted #5e5e5e` (secondary
text), `--rule #c4c4c4` (hairlines). Fonts `--font-sans` (Inter Tight),
`--font-mono` (IBM Plex Mono), weights `--regular 400`, `--bold 700`. Sizes
`--fs-huge` 42–100px, `--fs-large` 28–50, `--fs-medium` 20–26, `--fs-base`
16–18, `--fs-small` 13 (fluid from 360 to 1440px), with `--lh-*` and
`--track-*`. `--measure 66ch`. Space `--s1 8px`, `--s2 16px`, `--s3 24–32`,
`--s4 40–64`, `--s5 64–112`. Layout `--max 1240px`, `--gutter` 16/32/48px,
`--gap` 16/24px, `--cols` 4/12, `--header-h`. Lines `--hair` (1px grey),
`--line` (1px ink).

**Type classes.** `h1`/`.t-huge`, `h2`/`.t-large`, `h3`/`.t-medium`,
`h4`/`.t-base`, `.t-small` (mono 13px), `.label` (mono small grey), `.mono`,
`.sans`, `.muted`, `.bold`, `.regular`, `.lead` (medium text, 34em),
`.measure`, `.nowrap`. Links are underlined; `.link-quiet` underlines only on
hover and `aria-current="page"`.

**Buttons.** `.btn` (frame), `.btn--primary` (ink fill), `.btn--small`,
`.btn--block`, `.btn__caption` (mono second line). Hover inverts colours.
Focus: 2px ink outline, offset 3px, on everything.

**Rules and lists.** `hr`/`.rule` (hairline), `.rule--ink`, `.top-hair`,
`.top-line`; `.list-plain`; `.list-rules` (hairline between items and at the
end, `--s2` padding); `.list-comma` (inline list joined by commas).

**Grid.** `.wrap` (centred container with side gutters). `.grid`: 4 columns
below 720px, 12 from 720px; children span the full row unless given:
`.col-1`…`.col-12` and `.start-1`…`.start-12` (from 720px),
`.lg-col-1`…`.lg-col-12` and `.lg-start-*` (from 1080px), `.m-col-1`…`.m-col-4`
(below 720px). `.grid--tight` (row gap `--s2`), `.grid--flush` (no row gap).
Example: portrait 4 of 12 and text 8 of 12:

```html
<div class="grid">
  <div class="col-4 m-col-2">…</div>
  <div class="col-8">…</div>
</div>
```

`.cols` equal columns that wrap: `.cols-2`, `.cols-3` (from 720px), `.cols-4`
(2 from 720px, 4 from 1080px), `.m-cols-2` (2 below 720px).
`.scroll-row`: sideways scrolling row on phones and tablets, an even row of
`--row-items` (default 6) from 1080px (reels).

**Spacing.** `.stack` with `.flow-1`…`.flow-5` (gap between children),
`.cluster` (wrapping flex row), `.mt-0`…`.mt-5`, `.mb-1`…`.mb-5`,
`.pt-3`…`.pt-5`, `.pb-3`…`.pb-5`, `.sr-only`.

## 7. Behaviour and analytics

`src/scripts/telegram.ts` is the only client script (bundled into every
page by `BaseLayout`). It copies `data-tg-template` on click and swaps the
label for `data-tg-copied` during `data-tg-ms`, and, when `<html
data-metrika>` is set (production), sends `reachGoal` for elements with
`data-goal`: `telegram` (Telegram buttons and links), `email` (mailto links),
`hire` (footer link to /hire/), `product` (product buttons; pass
`goal="product"`). No other scripts: no `/#hire` redirect, no autoplay.

## 8. Routes and placeholders

`src/pages/index.astro` (/), `services/`, `cases/`, `products/`, `hire/`,
`guide/` (`index.astro` each), `404.astro`, and `work.html.ts` (redirect to
`/services/#formats` with meta refresh, canonical and a link). Phase 1 pages
render only the h1 and an empty element for each block anchor so that links
and anchors already resolve; replace the whole body when building a page.

## 9. Static files (`public/`)

Copied from the old site, unchanged, with their relative paths: `assets/`
(reels, posters, case images, testimonial videos and posters, approach
images, portrait, og.jpg, both PDF résumés), `resume/`, `demo/`
(`/demo/ai-competencies/`, `/demo/chatgpt-praktikum/`, `/demo/wishlist/`),
`en/` with the root `styles.css`, `script.js`, `game.js` it loads, and
`.nojekyll`. Product screenshots: `/products/top-pick.jpg`,
`/products/dobei.jpg`. Reel 01 (`assets/reels/reel-c1.mp4`,
`assets/reels/loops/c1.mp4`, `assets/posters/c1.jpg`) is not copied: it is
hidden until re-recorded and nothing links to it.
