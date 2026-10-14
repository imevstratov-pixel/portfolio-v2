# Components and content: reference for page builders

Everything a page needs is described here: commands, the content each page reads,
the helpers, the shared components and the CSS classes. Build pages only from
these pieces; add a new shared piece here when two pages need it.

Stack: Astro 7.3.8 (static output), no UI framework, TypeScript in components,
fonts from @fontsource (Inter Tight 400/700 and 400 italic, IBM Plex Mono 400,
Latin and Cyrillic subsets). Two small client scripts: Telegram copy and
analytics goals on every page, the carousel buttons on pages with a Carousel.

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
  `anchor` (`consulting`, `ai-agents`, `audit`, `course`, `app`, `game`,
  `guide`) on /services/, cases their `anchor` (`case-…`) on /cases/, products
  their `anchor` on /products/. Other pages link to these; `check-links` fails
  when one is missing. Anchors sit on elements that are always visible (the
  case article and its header, the service card), never inside a closed
  `<details>`.
- **Words.** No «Мост» and not the old production-line word for the AI
  service anywhere, in components, comments, drawings and anchors included
  (decisions 2 and 6 of 14.10): the service is «AI-агенты» (codeword
  «AI-агенты», anchor `#ai-agents`, its case `#case-ai-agents`), the drawing
  is AgentsScheme.
- **Images and video.** Fixed aspect ratios (component `Media`), lazy below the
  fold, alt text from the content. Video: native player, `preload="none"`,
  poster, no autoplay, no loop. The `loop` fields in the content are not used.
- **Less text, more pictures (decision 10 of 14.10).** Long texts fold into a
  native `<details class="disclose">` (no animation, no script): services
  «Подробнее», cases «Читать кейс полностью». Rows of people or screenshots
  are a `Carousel`.
- **A `class` passed to a child component does not get the parent's scoped
  styles.** Astro scopes a component's CSS to the elements it renders itself,
  so `<Resumes class="hero__resumes" />` styled in the parent does nothing.
  Wrap the child in an element of your own (`<div class="hero__resumes">…`)
  and style the wrapper, or use `:global()` on purpose.
- **Empty means absent.** A block, line or media item without content is not
  rendered (no placeholders). `Media` renders nothing for `src: ''`.

## 2. Commands

| Command | What it does |
| --- | --- |
| `npm run dev` | Dev server at `http://localhost:4321/portfolio-v2/` |
| `npm run build` | Static build into `dist/` |
| `npm run preview` | Serves `dist/` (Astro 7 may start it in the background; stop with `npx astro preview stop`) |
| `npm run check` | `astro check`: TypeScript and template types (0 errors expected) |
| `npm run check-links` | Every internal href/src/poster in `dist/` resolves, every `#anchor` exists on its page, no link leaves the base, no `/portfolio-v2/` literal in `src/`. Absolute URLs count as internal only for the page's own canonical, og:url and og:image; other links to the same host (sibling sites like `/skrizhal/`) are external |
| `npm run leakcheck` | Greps `dist/` for internal markers (see rules). Legacy files copied from the old site are reported, not failed, for `hidden`/`_note`; `--strict` fails on them too. Fails on any file under `dist/media/` that no generated page references (a screenshot waiting for Daniil's OK must stay outside `public/`). In preview it also fails on the Metrika counter anywhere in `dist/` and on any HTML page without a robots meta |
| `npm run shots -- --out shots/x / /services/` | Full-page screenshots at 375, 768, 1280 (`--widths 360,375` to change), reports horizontal overflow. Uses `/opt/pw-browsers/chromium` (override with `CHROMIUM_PATH`) and its own static server under the base path |
| `npm run verify` | build, check-links, leakcheck |
| `npm run content` | Re-run the content export (needs `SITE_CONTENT`) |

Environment: `BASE` (default `/portfolio-v2/`), `SITE` (default
`https://imevstratov-pixel.github.io`), `PREVIEW` (on unless `0`). In preview
every page has `noindex,nofollow` and no analytics, the legacy pages too
(`tools/legacy-preview.mjs`, an Astro integration, strips the Metrika snippet
from `dist/en/index.html` and adds the robots meta to legacy pages after the
build; `public/` stays verbatim); with `PREVIEW=0` the Yandex Metrika counter
111316684 is added and `<html data-metrika>` enables goals.
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
  services, getService, serviceByCodeword, serviceHref, servicePriceLine, serviceDurationLine,
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
  `<base>/services/#<anchor>`. `servicePriceLine(s)` is the service's own
  `price` or the global `work.price`, with a final period («Стоимость — после
  первого созвона.»); `serviceDurationLine(s)` gives «Срок: около недели.».
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

Props: `id` (anchor; adds `aria-labelledby` to `<id>-heading`),
`labelledby` (id of a heading inside the slot that names the section, when
`heading` is not passed; e.g. the `Steps` heading on the home page), `label`
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
`class`. The service cards on /services/ pass `hint={false} email={false}`
(the hint and the email stand once under «Не нашли своё?»); the /guide/ hero
passes the guide service's verb label («Заказать тренажёр») and no caption.

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
  line, lines; a codeword that belongs to a service shows the service's verb
  `button` label without a caption (decision 8 of 14.10), unless the block
  gives its own `label`;
- `button: { codeword, label, caption }` + `email: { text, subject }` (hire):
  primary Telegram button and the email as a second button
  (`TelegramEmailButtons`), `telegramText`, `resumes` (`Resumes`);
- `links` (products): a comma list of links under the text.
Props: `block`, `size` (`large` default, `huge`), `rule`, `class`.
On the home page the block shows the workload line; the texts renderer
describes the other pages' blocks as «как на главной», and the content of
those blocks already carries the same fields.

### TelegramEmailButtons, Resumes

```astro
<TelegramEmailButtons button={b.button} email={b.email} />   <!-- /hire/ first screen -->
<Resumes items={b.resumes} />
```

`TelegramEmailButtons`: the primary Telegram button (codeword, `label`,
`caption`) and, when `email.text` is given, the email as a second framed
button (subject and template from the codeword). No hint. `Resumes`: the PDF
links as sans text links with the meta in small grey mono. ContactBlock uses
both, so the /hire/ first screen and its contact block look the same.

### Steps

```astro
<Section id="how-we-start" labelledby="how-we-start-heading"><Steps headingId="how-we-start-heading"
  showConsultationNote={b.showConsultationNote} showPrepare={b.showPrepare} showWorkload={b.showWorkload} /></Section>
<Steps heading={false} level={3} showConsultationNote={false} showPrepare showWorkload={false} />
```

«Что будет после вашего сообщения» from `site.work.howWeStart`: heading, four
steps (large mono numbers from a CSS counter, «**Вы пишете.** text»), then the
optional lines. Props: `heading` (bool), `level` (2 or 3), `headingId` (id
of the heading, for `Section labelledby`), the three `show…` flags (take them
from the block: home `steps`, services `formats.howWeStart`), `class`.

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
<VideoTestimonial testimonial={t} layout="card" size="medium" />               <!-- a Carousel slide -->
<VideoTestimonial testimonial={it.t} extra={[it.company, it.relation]} layout="card" size="medium" />
<VideoTestimonial testimonial="evgenia" size="medium" />                         <!-- a full-width row -->
```

Poster in the native player (9:16) and the quote beside it with the
signature. `layout="card"` (home, /hire/, /cases/, always inside a
`Carousel`): a hairline on top, the video on 2 parts and the quote on 3 parts
of the card at every width, the quote at the base size on phones and in the
`size` from 720px. `layout="row"` (default, kept for client quotes): video 3
of 12 columns, quote 6 of 12; on phones a 7.5rem video column. Props:
`testimonial` (slug or entry), `extra`, `quote` (default true), `size`
(`large` default, `medium` for colleagues), `layout`, `class`.

### Carousel

```astro
<Carousel items={colleagues} label={heading} id="home-colleagues" bleed>
  {(t: (typeof colleagues)[number]) => <VideoTestimonial testimonial={t} layout="card" size="medium" />}
</Carousel>
<Carousel items={shots} kind="media" ratios={shots.map(ratio)} label={d.title} id={`${id}-gallery`} bleed>
  {(g: Shot, i: number) => <figure>…</figure>}
</Carousel>
```

A horizontal row of slides (decision 11 of 14.10): «Что говорят коллеги» on
the home page, /hire/ and the cases, and the product galleries. Pass the
items and a function child that renders one slide (`Astro.slots.render` with
the item and its index). The row scrolls with scroll snap (swipe on phones)
and always shows part of the next slide; under it «1 из 5» / «1–2 из 5» (the
slides fully in view, a polite live region, so the new position is
announced) and the buttons «Назад» and «Дальше», which move by one slide at
once (no smooth scrolling, no autoplay, they pause the row's videos). The
row is a focusable region named by `label` (`aria-roledescription`
«карусель», the arrow keys move by one slide), each slide a group «2 из 5»;
every slide stays in the DOM. The bar shows only after the script ran
(`data-ready`): without JS the row still scrolls and no counter can be
wrong; when every slide fits the script sets `data-static` and the bar goes;
one slide renders no bar.
Props: `items`, `label`, `id` (unique prefix), `kind` (`cards` default:
85% of the row on phones, 60% on tablets, 5 of 12 columns from 1080px;
`media`: one row height, 25rem phones, 26rem tablets, `height` or 30rem from
1080px, each slide as wide as its ratio allows, at most 85% (75% from
1080px)), `ratios` (width / height per item, `media` only), `height`,
`bleed` (the row runs into the side gutters, to the screen edges on phones),
`class`. Script: `src/scripts/carousel.ts`, bundled only on pages that use it.

### AgentsScheme (`components/scheme/`)

```astro
<AgentsScheme idPrefix={`${c.data.anchor}-scheme`} level={3} facts={false} />       <!-- /cases/ -->
<AgentsScheme level={5} titleSize="base" idPrefix={`${anchor}-scheme`} />         <!-- /hire/ -->
<AgentsScheme heading={false} facts={false} idPrefix={`${d.anchor}-scheme`} />    <!-- /services/ «Подробнее» -->
```

The multi-agent scheme from the old site (decision 12 of 14.10), redrawn as
an inline SVG in ink, paper and muted: input and the methodologist, the
distributor, the three groups of agents, the two human checks, the output
and the shared base. Its labels, heading («Как устроены AI-агенты»), facts
and hint live in the component (content field `scheme: "ai-agents"` only
switches it on); the texts renderer keeps a copy in `SCHEMES`, so change
both together. Every SVG label is at least 11 viewBox units and the drawing
is never scaled down (min-width 1180px, the viewBox width), so no label
renders under 11px. By the component's own width (container queries): from
1180px the drawing at the full width; 720–1179px the drawing at 1:1 scrolls
sideways with «Схему можно прокрутить вбок» above it; below 720px (phones,
tablets in portrait) the same labels as a vertical list (stages Вход,
Распределение, AI-агенты with the three groups and the two human checks,
Выход, the shared base; 1px frames, rules with small arrowheads). The facts
under it: a wrapping line with hairlines, a two-column list below 720px;
/cases/ passes `facts={false}` (the case infographic carries the numbers).
Give it the full container width (1184px at a 1280px window): on /cases/
under the case, on /hire/ as its own full-width row under the staff case, on
/services/ inside the AI-agents «Подробнее».
Props: `heading` (text or `false`), `level` (default 3), `titleSize`
(`medium` default, `base`), `facts` (list or `false`), `hint`, `idPrefix`
(unique per page), `class`.

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
<CaseLabels case={c} />                                  <!-- «В штате, EdTech, …, 2025–2026, Обучение, **в работе**» -->
<CaseCard case={it.case} line={it.line} linkLabel={b.cardLink} title="title" />
<CaseCard case="staff-c2" linkLabel="Читать кейс" service labels={false} />
```

CaseLabels props: `case`, `fields` (default origin, industry, year, duration,
direction), `status` (default true), `class`. The labels show in grey mono
capitals (CSS `text-transform`), the status in bold black. CaseCard props: `case`, `line`,
`linkLabel` (no link when omitted; the link goes to `/cases/#<anchor>`),
`title` (`shortTitle` default or `title`; the home featured cards use
`title`), `labels` (fields or `false`; default origin, industry, year,
direction, as on the home page), `service` (show the service short name),
`level`, `class`. Cards have a hairline on top; put them in `.cols.cols-2`.

### ServiceRow

```astro
<ul class="list-rules" role="list">
  {b.main.map((it) => <ServiceRow service={it.service} line={it.line} linkLabel={b.linkLabel} duration={b.showDuration} price action />)}
</ul>
<ul class="list-rules" role="list">
  {b.more.map((it) => <ServiceRow service={it.service} line={it.line} linkLabel={b.linkLabel} href={it.href} duration={b.showDuration} price action size="small" />)}
</ul>
```

An `<li>` with the compact logic of the service cards: title (full `title`,
bold), the line, «Срок: …» and the price line one under the other in the
same treatment as on the /services/ cards (base sans, the price line bold;
`duration`, `price`), then the verb link (`action`: the service's `button`, a Telegram
link that copies the start of the message, in bold) and «Подробнее»
(`linkLabel`; `href` override from the content, default `/services/#anchor`).
From 720px title on 5 columns and the rest on 7. Props: `service`, `line`,
`linkLabel`, `href`, `duration`, `price`, `action`, `size` (`large`,
`small`), `title` (`title` or `short`), `level`.

### Services on /services/ (`components/services/`)

`ServiceCard` renders every service as a compact card (decisions 8 and 10 of
14.10, `render_card()` and `render_service()` in the texts renderer): number,
title and the italic one-line `summary` (the full 6 columns) in columns 1–6;
the three `highlights` (dash list), «Срок: …» and the price line
(`servicePriceLine`, bold), the verb button (`TelegramAction` with
`label={button}`, no caption, no hint, no email line, so the Telegram
template mechanism stays) in columns 7–12. The copy hint and the email line
stand once in `ServicesIntro`, under «Не нашли своё?» (`intro.other.hint`,
`intro.other.email`). Under the card «Подробнее» (`details.disclose`)
opens the full template on the spot: body, `AgentsScheme` without heading and
facts for `scheme: "ai-agents"` (full width), «Для кого», «Что получите на
руки», «Сколько длится», «Как идёт работа», «Что нужно от вас», «Что не
входит», «Нейросеть и расходы», proof, «Мои продукты», «Что говорят
коллеги» (text quotes). The parts are `ServicePart` rows: label in columns
1–3, text in 4–12 (4–10 from 1080px). `short` (group variant `short`, the
guide): the same card with the `more` link («Подробнее о тренажёре», /guide/)
beside the verb button; its «Подробнее» opens only «Для кого» and «Что
получите на руки» (as the renderer). Phones: one column.
`ServiceGroup` renders a group (heading, lead, note with links, its cards),
`ServicesIntro` the h1, lead and table of contents, `Formats` #formats (see
5.1: the steps, the two payment formats, «Почему со мной предсказуемо» with
the work screenshots, the terms). Screenshots (`proofImages`): from 720px on
the 3-column grid of the «Почему со мной предсказуемо» items, each figure
starting on its column line; one height for all (the widest-ratio image
fills its column, the others are as wide as that height allows); on phones
one under the other, at most 24rem high; the caption under each in small
mono, a click opens the full image in a new tab (a plain link, no lightbox).

### Disclosure (`.disclose`, global.css)

```astro
<details class="disclose"><summary>{labels.more}</summary>…</details>
```

A native `<details>` whose `<summary>` looks like a small framed button and
ends with «+» / «−» (hover inverts, no animation, no script). Used by
`ServiceCard` («Подробнее») and `CaseArticle` («Читать кейс полностью»).

### Cases on /cases/ (`components/cases/`)

`CaseArticle`: an ink line, `CaseLabels`, the title (h2); then
`CaseInfographic` (`infographic`), the optional one-line `summary`, «Что из
этого сделаю для вас» (name in columns 1–3, the text in the medium size
beside it, the service title linked to /services/); a vertical reel beside
them (columns 11–12 from 1080px, 10–12 on tablets, a 7.5rem column beside
the service line on phones), spanning exactly the rows that render
(`--reel-rows`), so no empty row adds a gap. The full text (Контекст, Что сделал, Результат)
in «Читать кейс полностью» (`details.disclose`, rows: name 1–3, text 4–10).
After it, in the renderer's order: `AgentsScheme` (staff-c2), the links
(framed small buttons), the case testimonials as a `Carousel` of cards. The
anchor is on the article, so /cases/#case-… lands on the title.
`CaseInfographic`: the facts as large mono values with their labels under an
ink line (only the number is large: a qualifier before it, «около», «почти»,
«в», and a unit after it, «дня», «млн ₽», are set small beside it; a value
without a digit is bold sans at the medium size; every value box has the
height of one large mono line, so the labels of a row line up), two per row and all in one row from 560px of
available width; `flow` as numbered steps joined by 1px rules (a row from
560px, a column with a vertical rule below); `beforeAfter` as «Было» (grey)
and «Стало» (bold, ink line) side by side. Container queries, so it works
beside a reel and at the full width. «Шаги», «Было», «Стало» are the
renderer's labels. `CasesToc`: the groups (`TocGroups`: the service's short
name in small mono capitals, then the rows of `row.fields`, today the short
titles only, and the group's products with their labels in small mono on the
title's line). From 720px the table is open, the groups flow in 2 columns
(3 from 1080px); on phones it is folded in a native `<details>` whose summary
is the heading (h2) with «+» / «−». The two renderings carry the same links,
only one is displayed. The legend line under each.

### Products on /products/ (`components/products/`)

`ProductItem`: kind, the name in huge type. A `gallery` of two or more
(decision 14 of 14.10) is a `Carousel` of `kind="media"` right under the name
(screenshots with a hairline frame and native videos with posters, the
caption under each), then the text in columns 1–7 and `ProductFacts` in
9–12. One picture (the gallery's only item, or `media` when there is no
gallery): the screenshot with its caption in the side column, the facts under
the body. The first gallery item is also `media` in the content; it is shown
once. Every screenshot is a plain link to the full file (new tab, no
lightbox). Only the first picture of the first product loads eagerly
(`first`), the rest lazily. Status labels, the action button, secondary links
and the quiet Telegram link are as before.

### Home «Обо мне» and /hire/ «Опыт»

`home/About`: `photo { src, alt }` (decision 9 of 14.10) replaces the drawn
`portrait` in the same column when it is visible (a 4:5 frame, half the width
on phones); hidden now, so the drawn portrait shows. Tested locally with a
placeholder photo. `hire/Experience`: the staff cases (`show: full`) are rows
of the place's grid in columns 4–12; a case with `scheme: true` gets the
`AgentsScheme` (heading at the base size, h5) under it across all 12 columns.
`hire/StaffCase` no longer draws a scheme. `hire/HireTestimonials` and
`home/Testimonials` render the colleagues as a `Carousel` of cards.

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
- `services` (services): `heading`, `lead`, `showDuration`, `main[{ service, line }]`, `moreHeading`, `more[{ service, line, href? }]`, `linkLabel` (each row also shows the price line and the service's verb `button`)
- `reels` (reels): `heading`, `hint`, `linkLabel`, `items[{ case, video, loop, poster, hook }]` (use `video` + `poster`; `.scroll-row`)
- `featured-cases` (cases): `heading`, `cardLink`, `items[{ case, line }]`, `fallback[]`, `returnLine { text, cases[] }` (show only when all its cases are published), `allLink { label, href }`
- `how-we-start` (steps): `source`, `showConsultationNote`, `showPrepare`, `showWorkload` (component `Steps`)
- `testimonials` (testimonials): `heading`, `headingColleaguesOnly`, `clients.items[]` (empty now, so the heading is `headingColleaguesOnly`), `colleagues { caption, hint, items[] }` (a `Carousel`)
- `about` (about): `heading`, `portrait`, `portraitAlt`, `photo? { src, alt }` (hidden until Daniil sends the photo; when visible it replaces `portrait` here), `text[]`, `experience[{ years, place, role, note }]`, `experienceLink { label, href }` (`/hire/#experience`), `productsLine { text, linkLabel, href }`
- `contact` (contact): `anchor`, `heading`, `hint`, `buttons[]`, `email`, `lines[]`, `workload`

**services**: `serviceTemplate { labels { forWhom, youGet, duration, steps, fromYou, notIncluded, ai, proof, proofLinks, proofCasesBuilt, proofProducts, testimonials, readCase, more }, button { source, hint, email } }`
- `intro` (intro): `heading` (h1), `lead[]`, `toc.items[]` (service slugs, show `short`), `other { text, button }` (codeword «Другое»)
- `group-learning`, `group-development`, `group-personal` (service-group): `heading`, `lead?`, `note? { text, links[{ label, service | case }] }`, `services[]`, `variant?` (`short` → `ServiceCard short`)
- `formats` (formats, anchor `formats`): `heading`, `howWeStart { showConsultationNote, showPrepare, showWorkload }`, `pricing { heading, items[{ title, points[] }] }`, `predictable { heading, items[{ title, text }] }`, `proofImages[{ src, alt, caption, status? }]` (the work screenshots under «Почему со мной предсказуемо»; hidden ones are dropped by the export), `terms { heading, items[{ id, text } | { id, source }] }` (`gref(source)`)
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
- `experience`: `anchor`, `heading`, `lead`, `caseDisplay { sections[], showReel, … }`, `items[{ id, dates, duration?, role, place, placeFull?, placeNote?, about, results?[], stack?, cases?[{ case, show: 'line' | 'full', links?, scheme? }] }]` (`line` shows `case.hire.line`; `full` shows the case sections without labels and without the service line; `scheme: true` adds the case's AgentsScheme under it at the full width)
- `testimonials`: `anchor`, `heading`, `hint`, `items[{ testimonial, company, relation }]` (a `Carousel`)
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

`title`, `short`, `codeword`, `anchor`, `line` (Обучение, Разработка),
`order`, `summary` (the italic one-liner of the card), `button` (verb label
of the visitor's action: «Записаться на консультацию», «Обсудить
AI-агентов», «Заказать аудит курса», «Обсудить курс», «Обсудить приложение»,
«Обсудить игру», «Заказать тренажёр»), `highlights[3]` (the card's three
points), `forWhom[]`, `youGet[]`, `duration`, `durationNote?`,
`steps[]`, `fromYou?`, `ai?`, `notIncluded[]`, `proofCases[]`,
`proofNotes? { caseSlug: note }`, `proofLinks?[{ label, url, note?, case?, product? }]`,
`proofProducts?[]`, `testimonials?[]`, `more? { label, url }`,
`related? { text, service?, case? }`, `price?` (absent for now: the card
shows `site.work.price`), `scheme?` (`"ai-agents"` on ai-agents); body: one
paragraph (`bodyHtml`). Slugs and anchors: consulting, ai-agents, audit,
course, app, game, guide. Card (render_card): highlights, «Срок: …» and the
price line, the verb button. Full template order (render_service, inside
«Подробнее»): body, the scheme, «Для кого»,
«Что получите на руки», «Сколько длится» (`duration + '. ' + durationNote`),
«Как идёт работа» (numbered), «Что нужно от вас», «Что не входит»,
«Нейросеть и расходы» (`ai`), proof: for `app` first «Что можно открыть»
(`proofLinks`) then «Что я написал сам» (`proofCases`); for others «Чем
подтверждено» (published `proofCases` with notes, then `proofLinks`), then
«Мои продукты» (visible `proofProducts`: title and `oneLiner`); «Что говорят
коллеги» (`testimonials`).

### 5.4 cases (18 published, `cases`)

`title`, `shortTitle`, `origin`, `industry`, `year`, `duration?`, `direction`,
`service` (codeword), `anchor`, `status?` («в работе»), `featured`, `order`,
`published`, `hire? { place, line? }`, `links?[{ label, url, note? }]`,
`reel? { video, loop, poster }`, `scheme?` (`"ai-agents"`, staff-c2 only:
`AgentsScheme`), `infographic? { facts[2–4]{ value, label }, flow?[2–5], beforeAfter? { before, after } }`
(every case has one; facts only from the case text), `summary?` (optional
one-liner under the infographic; no case has it yet), `testimonials?[]`.
Body sections: «Контекст», «Что сделал», «Результат», «Что из этого сделаю
для вас» (`bodySections`).

### 5.5 products (5, `products`)

`title`, `anchor`, `codeword`, `kind`, `status`, `platform`, `oneLiner`,
`inside`, `statusNote?`, `visible`, `action? { label, url }` (no action means
no button: the two party games), `secondaryLinks?[{ label, url, note? }]`,
`media { type, src, alt, status }` (the first gallery shot, or the one
screenshot), `gallery[{ type: image | video, src, poster?, alt, caption? }]`
(wishlist 5, Barba 4, Скрижаль 3, Top Pick and ДОБЕЙ 1; videos from Daniil
go first with a poster), `messageLink { label, template }`
(`productTemplate(p)`), `metrics[]`, `order`; body paragraphs (`bodyHtml`).
Product names use the huge size.

### 5.6 testimonials (5)

`name`, `role`, `company` (may be ''), `kind` (`video`), `video`, `loop`,
`poster`, `quote`, `pages[]`. Use `VideoTestimonial` (`layout="card"` in a `Carousel`).

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
end, `--s2` padding); `.list-comma` (inline list joined by commas);
`.list-dash` (a grey dash hangs in front of each item) and `.list-num` (a
small grey mono number in front of each item), both at `--measure`. Numbered
lists inside `.prose` get the same number treatment as `.list-num`.

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
`.scroll-row`: sideways scrolling row on phones and tablets (items 42% of
the row, at least 9.5rem; from 720px 28%, at least 11rem, so the row scrolls
instead of shrinking), an even row of `--row-items` (default 6) from 1080px
(reels).

**Spacing.** `.stack` with `.flow-1`…`.flow-5` (gap between children),
`.cluster` (wrapping flex row), `.mt-0`…`.mt-5`, `.mb-1`…`.mb-5`,
`.pt-3`…`.pt-5`, `.pb-3`…`.pb-5`, `.sr-only`.

## 7. Behaviour and analytics

Two client scripts. `src/scripts/carousel.ts` (bundled by `Carousel` only
on pages with a carousel: home, /cases/, /products/, /hire/) wires «Назад»
and «Дальше», the arrow keys and the counter (section 4, Carousel).
`src/scripts/telegram.ts` is bundled into every page by `BaseLayout`. It copies `data-tg-template` on click and swaps the
label for `data-tg-copied` during `data-tg-ms`, and, when `<html
data-metrika>` is set (production), sends `reachGoal` for elements with
`data-goal`: `telegram` (Telegram buttons and links), `email` (mailto links),
`hire` (footer link to /hire/), `product` (product buttons; pass
`goal="product"`). No other scripts: no `/#hire` redirect, no autoplay, no
lightbox (the work screenshots open as plain links), the disclosures are
native `<details>`.

## 8. Routes

`src/pages/index.astro` (/), `services/`, `cases/`, `products/`, `hire/`,
`guide/` (`index.astro` each), `404.astro`, and `work.html.ts` (redirect to
`/services/#formats` with meta refresh, canonical and a link). Every page
renders its content blocks in the content order, as the texts renderer does.

## 9. Static files (`public/`)

Copied from the old site with their relative paths (unchanged, except the
posters `assets/testimonials/posters/evgenia.jpg` and `liza.jpg`, re-cut from
a frame without the burned-in subtitles that named the person in full):
`assets/`
(reels, posters, case images, testimonial videos and posters, approach
images, portrait, og.jpg, both PDF résumés), `resume/`, `demo/`
(`/demo/ai-competencies/`, `/demo/chatgpt-praktikum/`, `/demo/wishlist/`),
`en/` with the root `styles.css`, `script.js`, `game.js` it loads, and
`.nojekyll`. Product screenshots: `/products/top-pick.jpg`,
`/products/dobei.jpg`. Reel 01 (`assets/reels/reel-c1.mp4`,
`assets/reels/loops/c1.mp4`, `assets/posters/c1.jpg`) is not copied: it is
hidden until re-recorded and nothing links to it.
