---
name: groktopus-branding
version: 1.1.0
description: >-
  Generate images, logos, and visual content consistent with the Groktopus brand identity.
  Use when creating site-wide visuals for groktop.us — logos, hero images, feature graphics,
  social media assets, and promotional materials. Covers brand color palette derived from
  the canonical vintage-etching logo, typography (Bodoni/Didot-style high-contrast serif),
  the Groktopus octopus logomark (exposed-brain concept), cover illustration standards,
  and reference-image-driven generation via the image edit API.
tags: [groktopus, brand, identity, logo, illustration, editorial, image-generation, style-guide, enterprise-ai]
sources:
  - https://www.groktop.us
  - CSS variables extracted from groktop.us site stylesheet (2026-05-24)
  - Groktopus logo — Podchaser cached image (vintage scientific etching)
  - Groktopus LinkedIn banner — LinkedIn media library
  - Groktopus Cover Image Template — image-groktopus skill
related_skills:
  - blog-it
---

# Groktopus Branding — Generate Groktopus-Aligned Visual Content

This skill encapsulates the visual brand identity of **Groktopus**, the enterprise AI strategy publication at groktop.us. Use it to produce images, illustrations, logos, and promotional visuals consistent with the Groktopus aesthetic — a blend of vintage scientific illustration, painterly editorial art, and modern analytical clarity.

---

## Brand Philosophy

Groktopus writes about the intersection of AI, enterprise strategy, and organizational transformation. The brand identity reflects this through three pillars:

1. **Intelligence with Depth** — The octopus with an exposed brain is the core metaphor: deep understanding (grok), multi-tentacled awareness, strategic thinking. Nothing is surface-level.
2. **Analytical Edge** — Clean, professional, but never sterile. The palette is anchored in warm parchment (`#e8d9c0`) with maroon ink (`#65413a`) accents and navy (`#132345`) text. Authority through restraint, not flash.
3. **Vintage-Meets-Modern** — The logo traces to 19th-century scientific etching, and the web design now matches: single parchment mode, no dark/light toggle. Anachronism is deliberate: authority from the past, relevance to the future.

**Core tagline:** "Human-led AI transformation starts here."

**Brand voice:** Imperative, analytical, signal-focused. Data-driven argumentation. Case-study based. Literate but not academic. The tone maps to *The Economist* or *Stratechery* — confident, research-backed, with genuine opinion.

> **Full strategy documentation:** See [[Groktopus Brand Strategy]] in the vault for positioning, competitive landscape, audience personas, and core values.
>
> **Full voice guidelines:** See [[Groktopus Voice]] in the vault for tone matrix, vocabulary rules, and copy examples.

---

## Logo: The Groktopus Mark

### Concept

The logo is an **octopus with an exposed brain** — a visual pun merging two concepts:
- **Grok** (from Heinlein's *Stranger in a Strange Land*) — to understand something so deeply you become one with it
- **Octopus** — intelligence, adaptability, multi-tentacled awareness

The brain sits atop the octopus's head in cross-section, rendered with grid-like cortical detail. The tentacles curl outward and inward in roughly symmetrical composition.

### Current Logo (2026) — Vintage Scientific Etching

| Element | Description |
|---------|-------------|
| **Style** | 19th-century natural history engraving / scientific etching. Fine linework, hatching and cross-hatching, stippling for texture. |
| **Format** | Circular badge — octopus + brain enclosed within a double-ringed circle (solid outer ring, dotted inner ring). |
| **Typography** | "GROKTOPUS" arched across the top of the circle in a classic high-contrast serif typeface (Bodoni or Didot family — tall, condensed, extreme thick/thin contrast). Navy blue. |
| **Colors** | **Maroon ink** (`#65413a`) octopus on **parchment** (`#e8d9c0`) background. **Navy** (`#132345`) text. **Border grey** (`#454f62`) outer circle. |
| **Tentacles** | 8 tentacles, curled with symmetric arrangement to fill the circle. Sucker circles detailed along underside in neat parallel rows. |
| **The Brain** | Human brain cross-section with visible gyri and sulci, rendered with grid-like cortical pattern, replacing the top of the head. Distinguishable from smooth mantle by texture density. |

### Logo Color Variants

| Variant | Illustration | Text | Background | Use case |
|---------|-------------|------|------------|----------|
| **Canonical (Vintage)** | Maroon (`#65413a`) | Navy (`#132345`) | Parchment (`#e8d9c0`) | Primary logo — all official brand contexts, print, about page |
| **Inverted** | Parchment (`#e8d9c0`) | Parchment (`#e8d9c0`) | Navy (`#132345`) | Dark-background applications, header overlays |
| **Monochrome dark** | White | White | Transparent | Social media avatars on dark backgrounds |
| **Monochrome light** | Navy (`#132345`) | Navy (`#132345`) | Transparent | Light document headers, low-ink print |

### Logo Usage Rules

- Always maintain clear space equal to 1× the logo height on all sides
- Never outline, shadow, or apply effects to the logomark
- Never place the vintage etching variant on midtone backgrounds — high contrast only
- The circular badge format is the primary logomark — do not crop or reshape it
- The illustration and text are a single unit — never separate the octopus from the "GROKTOPUS" wordmark
- The logo format should be square or circular — never horizontal lockups

---

## Color Palette

The Groktopus brand has two complementary color systems. The **canonical palette** is derived from the vintage etching logo and is the primary brand identity. The **web palette** comes from the groktop.us Ghost theme and is used for the digital presence.

### Canonical Palette (Logo-Derived — Primary Brand Identity)

Extracted computationally from the canonical logo image `openai_gpt-image-2-medium_20260524_143932_51b0dbf4.png`.

| Color | Hex | RGB | Usage |
|-------|-----|-----|-------|
| **Parchment** | `#e8d9c0` | (232, 217, 192) | Primary background — warm aged paper |
| **Maroon Ink** | `#65413a` | (101, 65, 58) | Logo illustration — octopus linework, primary ink color |
| **Navy** | `#132345` | (19, 35, 69) | Logo text — "GROKTOPUS" wordmark, headings, primary text |
| **Border Grey** | `#454f62` | (69, 79, 98) | Logo outer circle, secondary borders |

### Single Web Palette (Parchment Mode)

The groktop.us Ghost theme uses a single parchment-based mode — no dark mode, no light toggle. The canonical palette IS the web palette.

| Color | Hex | RGB | Usage |
|-------|-----|-----|-------|
| **Parchment** | `#e8d9c0` | (232, 217, 192) | Page background |
| **Card Surface** | `#f0e6d4` | (240, 230, 212) | Card and surface backgrounds |
| **Hover Surface** | `#dac8a8` | (218, 200, 168) | Hover states, secondary surfaces |
| **Border** | `#c9b89a` | (201, 184, 154) | Dividers, card borders |
| **Primary Text** | `#132345` | (19, 35, 69) | Body text, headings — navy |
| **Secondary Text** | `#4a4f63` | (74, 79, 99) | Metadata, secondary labels |
| **Muted Text** | `#8a8f9f` | (138, 143, 159) | Captions, placeholders |
| **Accent Maroon** | `#65413a` | (101, 65, 58) | Primary accent — links, tags, buttons, emphasis |
| **Accent Amber** | `#8e7353` | (142, 115, 83) | Secondary accent — hover highlights, warm accents |
| **Link** | `#65413a` | (101, 65, 58) | Hyperlinks, inline references |

### Hero Gradient

```
linear-gradient(90deg, #65413a, #8e7353, #132345)
```
*Maroon → Amber → Navy* — used for the progress bar, home hero divider, and decorative elements. Replaces the earlier blue→violet→pink gradient.

### Palette Principles

- **Single parchment mode** — no dark mode, no light toggle. The site uses one consistent palette based on the canonical brand colors.
- **High contrast between parchment (#e8d9c0) and navy (#132345)** — the warm base against deep navy text is the signature color relationship.
- **The gradient (maroon→amber→navy) is a decorative accent** for the progress bar and hero divider — not for the logo.
- **Maroon (#65413a) is the single accent color** — used for links, tags, buttons, and hover states. No competing accent colors.
- **No pure black, no pure white** — everything is tinted warm or cool to match the parchment base.

> **Full visual identity:** See [[Groktopus Visual Identity]] in the vault for the complete color palette, typography scale, logo variants, and illustration standards.

---

## Typography

The brand typography is anchored by the canonical logo typeface — **a high-contrast serif in the Bodoni/Didot family**. This is the typeface used for "GROKTOPUS" in the logo and extends to all brand-facing communications. The web presence uses complementary web-safe fonts.

### Brand Typeface (Logo-Derived)

| Role | Typeface | Character | Usage |
|------|----------|-----------|-------|
| **Display / Wordmark** | Bodoni, Didot, or similar high-contrast serif | Extreme thick/thin contrast, tall and slightly condensed, elegant hairlines, strong vertical stress | "GROKTOPUS" logo wordmark, print headlines, formal brand contexts |

The logo typeface is a **classic high-contrast serif** similar to Bodoni (Giambattista Bodoni, 1798) or Didot (Firmin Didot, 1784–1811). Key characteristics:
- Extreme contrast between thick stems and thin hairlines
- Tall, condensed letterforms with strong vertical stress
- Flat, unbracketed serifs (hairline serifs)
- Geometric construction — letters feel architectural rather than calligraphic
- The anachronistic choice is deliberate: an 18th-century typeface for a 21st-century AI publication signals that depth and rigor transcend eras

### Web Typography (Single Mode)

| Role | Font | Fallback | Usage |
|------|------|----------|-------|
| **Display / Wordmark** | Playfair Display | Georgia, serif | Logo / site title — high-contrast serif matching brand typeface, solid navy `#132345` |
| **Article Heading** | Fraunces | Georgia, serif | Article titles, section headers, hero text on the website |
| **Body** | Atkinson Hyperlegible | Arial, sans-serif | All article body text, bylines, metadata |
| **Monospace** | Courier New | Courier, monospace | Code blocks, inline code, technical data |

### Typography Scale

| Token | Size | Use |
|-------|------|-----|
| `--text-xs` | 0.75rem (12px) | Tags, metadata, captions |
| `--text-sm` | 0.875rem (14px) | Post card excerpts, secondary labels |
| `--text-base` | 1.125rem (18px) | Body text, article content |
| `--text-lg` | 1.25rem (20px) | Blockquotes, subheadings |
| `--text-xl` | 1.5rem (24px) | Section headers, sidebar titles |
| `--text-2xl` | 1.875rem (30px) | Article h2, feature subheaders |
| `--text-3xl` | 2.25rem (36px) | Article h1, major section heads |
| `--text-4xl` | 3rem (48px) | Hero headline (desktop) |

### Typography Principles

- **Anachronism is intentional** — Courier New as the monospace choice (a typewriter font for a publication about cutting-edge AI) reinforces the vintage-meets-modern identity. The heading serif (Fraunces) carries a literary, almost academic weight. This is a publication that reads, not a product that sells.
- **Atkinson Hyperlegible** is a deliberately inclusive choice — designed for readers with low vision, it communicates care for the reader's experience.
- **Headings get tight letter-spacing (-0.02em)** — a subtle editorial squeeze that signals confidence.
- **Navigation is uppercase, small, tightly tracked** — 0.04em letter-spacing, 0.75rem size, 700 weight. This is the analytical register.

> **Full typography spec:** See [[Groktopus Visual Identity]] in the vault for the complete type scale, font roles, and principles.

---

## Brand Voice Quick Reference

> Full voice guidelines with tone matrix, vocabulary rules, and copy examples at [[Groktopus Voice]] in the vault.

| Dimension | Description |
|-----------|-------------|
| **Authority** | Confident, research-backed, data-driven. Makes arguments, not just observations. |
| **Register** | Analytical but accessible — *The Economist* or *Stratechery*, not an academic journal. |
| **Sentence structure** | Short, declarative. Imperative openings. "The 30% Threshold: Why Salesforce's AI Work Ratio Changes Everything." |
| **Tone toward subjects** | Critical but fair. Calls hype cycles, celebrates genuine breakthroughs. |
| **Signal framing** | Views industry moves as signals of deeper structural patterns — names the pattern, not just the event. |
| **"Human-led"** | The core framing — AI is a tool in human hands, not an autonomous force. Every article reinforces this. |
| **Titles** | Strong claim + colon + payoff: "Your AI Strategy Needs a Second Opinion. We Built a Free One." |

---

## Cover Image Standards

### Visual Language (Brief)

The Groktopus cover image identity uses a **vintage steel engraving / etched illustration** style matching the canonical logo. The old painterly watercolor standard has been retired.

- **Medium**: Simulated steel engraving — fine cross-hatching, stippling, linework. Warm parchment background (`#e8d9c0`). Maroon ink (`#65413a`) for linework and shadows. Navy (`#132345`) for depth and weight.
- **Style**: 19th-century engraved plate tradition — like plates in a scientific atlas or engineering schematic
- **Format**: Landscape, 16:9 or 3:2. Reads at 720px and up to 2000px.
- **Palette**: Warm parchment dominant, maroon linework, navy accents — the canonical palette only
- **Lighting**: Dramatic chiaroscuro. Single light sources — lamplight, window light, overhead fluorescents. Felt rather than seen.
- **Mood range**: From melancholic (layoffs, displacement) to uneasy-critical (strategic critique) to analytical-cinematic (corporate analysis) to hopeful-but-grounded (transformation)

### Hard Rules for Cover Images

- Never include text, lettering, logos, or words
- No generic AI clichés (glowing brains, circuit boards, robot hands, binary code)
- No stock-photo framing (laptops-with-coffee, diverse-hands-at-table, tech-hexagon skylines)
- No editorial-cartoon flatness (single-line outlines, white-paper negative space)
- No photorealism — this is painted or engraved illustration
- **At least one human subject** should be present — we are "human-led AI transformation"
- **Represent diversity explicitly** — subjects of all ages, races, genders, body types, and abilities. Describe these details in every prompt.
- **No stereotypical white man in a business suit.** This is the single most important negative rule. Clothing is casual to business casual — sweaters, cardigans, open collars, glasses, rolled sleeves. White men are not off-limits, but when they appear, describe them with specific detail (age, features, context, casual clothing) rather than defaulting to a generic executive archetype.
- Subject descriptions must explicitly include age, race, gender, and attire — the image generator defaults to a white man if you don't specify otherwise.
- **The anachronism is in the TECHNIQUE, not the subjects.** The artistic style is 19th-century steel engraving. The people and settings are thoroughly modern — contemporary clothing (henleys, cardigans, open collars, glasses), modern technology (screens, laptops, network diagrams), current professional contexts. The tension between the vintage rendering and the modern subject matter is an intentional and defining feature of the brand identity. Never dress subjects in 19th-century period clothing.
- **No photorealism** — vintage steel engraving / etched illustration style. Cross-hatching, stippling, warm parchment background.

### Tonal Register by Article Type

| Article type | Palette | Lighting | Composition | Mood reference |
|---|---|---|---|---|
| Layoffs / displacement | Heavy maroon hatching, navy shadow | Stark, cold single source, deep shadows | Figures isolated by architectural scale | Hopper — urban stillness, solitary figures in empty spaces |
| Strategic critique | Dense maroon cross-hatch, navy mist | Surreal single shaft, partial illumination | Wide, theatrical, crowd vs figure | Goya — satirical scale, structural critique through composition |
| Scientific discovery | Fine maroon stippling, navy dotted lines | Crepuscular shaft through darkness, luminous | Deep perspective, vanishing point | Piranesi — vast interiors, dwarfing scale, discovery through architecture |
| Transformation success | Warm maroon linework, sparse navy accents | Golden-adjacent warm tone, single lamp | Motion implied, forward-leaning composition, human plus luminous presence | Dürer — precise, hopeful, humanist, centered on craft |
| Corporate analysis | Maroon grid lines, navy architectural framing | Cold angular light, geometric shadows | Cinematic wide, symmetrical, architectural | Doré — organizational scale, the individual within the machine |
| Workforce / human-AI | Maroon figurework, navy connective lines | Mixed — warm human side, cool architecture side | Figures in scale, connective lines, spatial relationship | Daumier — workers in context, dignity in labor, social dynamics |

---

## Logo & Identity Image Generation

### Core Principle: Two Tools, Two Jobs

Groktopus brand image generation uses two tools for two fundamentally different jobs:

**1. Edit API (scripts/generate-with-ref.py) — for editing AROUND existing images**
- Uploads an existing image (the canonical logo, the brand card) and edits elements AROUND it
- Works brilliantly for: brand cards, identity sheets, adding palette swatches and typography around a preserved logo
- The `--pad` flag extends non-square images with edge color so the model has room to add content
- **Does NOT work for:** generating new scenes "in the style of" a reference. The edits endpoint edits the image you upload — it does not learn from it as a style reference

**2. Text-to-image (image_generate tool) — for NEW scenes (covers, inline charts)**
- Required when generating a completely new composition (a cover scene, a diagram, a chart)
- Brand identity is carried in the prompt language: the vintage steel engraving description, the exact color hex values, the cross-hatching technique
- **Critical:** The edit API CANNOT do style transfer. Uploading the brand card and asking for a cover "in the same style" produces a blank or degraded image. New scenes must be generated via text-to-image with a detailed brand prompt.

**Workflow order:** Generate new scenes via text-to-image first (using the brand prompt templates in this skill). Then, if you need to add elements around an existing image (like placing the logo into a layout), use the edit API with --pad.

## Quick Start: Which Method to Use

| You want to generate... | Use this method |
|---|---|
| A new cover for an article | → **Cover prompt templates** (text-to-image — Pattern A-E below) |
| An inline diagram or chart | → **Inline Illustration templates** (text-to-image) |
| Migrate an old cover to the engraving style | → **Cover Image Migration** (edit API with reference — Method 6) |
| A brand card or identity sheet | → **Brand Card Generation** (edit API with logo — Method 1) |
| A section divider / pull-quote ornament | → **Feature Graphic** (edit API with logo — Method 4) |
| A social media avatar | → **Avatar** (text-to-image — Method 2) |
| A new site banner | → **Site Banner** (text-to-image — Method 7) |
| Full brand documentation | → **Vault docs** at `99/Groktopus Brand/` |

### Primary Method: Brand Card Generation (Edit API with Reference)

This is the canonical workflow for generating a brand reference card or any asset that must preserve the logo exactly:

```bash
python3 scripts/generate-with-ref.py \
  --prompt "This is a circular vintage scientific etching logo for GROKTOPUS — \
an octopus with an exposed human brain in deep maroon ink on warm cream \
parchment with the word GROKTOPUS in navy high-contrast serif arched across \
the top. Keep this logo exactly as-is. Extend the parchment background. Add \
[describe what to add — color swatches, typography, layout elements]. \
Vintage-academic style on aged paper. Only the original GROKTOPUS badge logo \
remains as illustration." \
  --reference assets/groktopus-logo-vintage.png \
  --aspect landscape \
  --pad \
  --quality high
```

**Key parameters:**
- `--pad` — critical. Pads the square logo to landscape with the dominant edge color so the model extends the background rather than cropping
- `--aspect landscape` — 1536×1024 output, enough room for logo + palette + typography side by side
- `--reference` — the canonical logo or brand card
- The prompt must explicitly say "Keep this logo exactly as-is"

**Brand card anatomy (proven layout):**
- LEFT: Canonical logo preserved intact
- RIGHT TOP: Color palette — 4 labeled swatches in a row (Parchment #E9DFC6, Maroon Ink #5C1F1F, Navy #142A4D, Border Grey #6B6B6B)
- RIGHT MIDDLE: Typography specimen — uppercase alphabet + numbers in proportional high-contrast serif (Bodoni/Didot style). Must specify PROPORTIONAL (not monospace) in the prompt
- BOTTOM CENTER: Thin rule with tagline "Human-Led AI Transformation." in serif, flanked by ornamental flourishes

### Method 2: Social Media / Avatar Variant

For avatar-sized versions — use the edit API with the canonical logo as reference when possible, or text-to-image when no reference exists:

```
A circular brand avatar for "Groktopus" — minimalist flat vector of an octopus
with an exposed brain, designed to read clearly at 256×256 pixels. The octopus
is simplified to 6 visible tentacles arranged in a radial star pattern, with a
small brain silhouette on top. Solid navy (#132345) background. The
octopus is rendered in maroon (#65413a) with warm parchment (#e8d9c0) brain accent.
Clean, bold, scalable. No text. Avatar format.
```

### Method 3: Cover Images (Text-to-Image with Brand Prompt)

Cover images require text-to-image generation — the edit API cannot create new scenes from references. Use the `image_generate` tool with `aspect_ratio: landscape` and a prompt built from the brand identity:

1. Open with the vintage steel engraving style spec: `"A vintage steel engraving, 19th-century steel engraving style. Warm cream parchment background (#e8d9c0). Fine cross-hatched ink linework in deep maroon (#65413a) with navy (#132345) shadows."`
2. Describe the scene: subject, setting, lighting, composition, emotional register
3. Specify what's NOT in the image: "No text, no lettering, no logos"
4. End with: "No text, logos, or lettering in the image."

See the `assets/` folder for 5 worked examples of cover compositions that match the Groktopus brand. The composition patterns are analyzed in `references/cover-composition-patterns.md`.

### Cover Prompt Templates by Composition Pattern

Each template is a complete text-to-image prompt. Replace `[article-specific detail]` with the article's subject. Always specify age, race, gender, and attire for any human subject — the generator defaults to a white man in a suit if you don't.

See `references/cover-composition-patterns.md` for the full composition analysis (subjects, settings, vibes) behind each pattern, and `references/cover-prompt-templates.md` for the complete ready-to-use prompt templates.

#### Pattern Selection Quick Reference

| Article Type | Pattern | Tonal Register | Artist Reference | Key Subject Elements |
|-------------|---------|---------------|------------------|---------------------|
| AI strategy, frameworks, decision analysis | **A — Strategy Session** | Corporate analysis | Doré | Diverse professionals around table, papers, split lighting |
| Layoffs, workforce cost, burnout | **B — Burnout at Scale** | Layoffs/displacement | Hopper | Vast auditorium, single podium figure, infinity symbols |
| CEO critique, governance failure, structural harm | **C — Founder Critique** | Strategic critique | Goya | Commanding foreground figure, rows of workers, mist |
| Post-mortems, reflection, leadership analysis | **D — Weight of Decision** | Scientific discovery | Piranesi | Single figure, empty boardroom, window light |
| Positive transformation, human-AI teaming, case studies | **E — Human-AI Collaboration** | Transformation success | Dürer | Person at desk + luminous data-form, hopeful |

For the full tonal register table (palette, lighting, composition details per mood), see the **Tonal Register by Article Type** section above. For detailed composition analysis per pattern, see `references/cover-composition-patterns.md`.

Patterns A-E full prompt templates have been moved to `references/cover-prompt-templates.md` to reduce inline loading. Load that reference when you need the complete ready-to-use prompt text.

### Cover Migration from Alt Text

When migrating existing articles from old covers to brand-style covers, read the article's `feature_image_alt` as the compositional brief. See `references/cover-generation-workflow.md` for the full workflow: read alt text → strip old palette colors → inject diversity + modern attire → generate → upload → swap feature_image.

### Method 4: Feature Graphic / Section Divider

For eye-catching feature graphics between sections or as pull-quote accompaniments — rendered in the canonical parchment palette:

```bash
python3 scripts/generate-with-ref.py \
  --prompt "A decorative section divider for a Groktopus article. Vintage engraved style on warm cream parchment background (#e8d9c0). A single thin maroon ink (#65413a) line traces the silhouette of an octopus tentacle curling gracefully across the frame, rendered as fine cross-hatched linework. A navy (#132345) dotted line follows the tentacle's curve. At the curl tip, a small amber (#8e7353) stippled glow. No text. Minimalist — just the single tentacle curl as an ornamental break between sections. The engraving style matches the Groktopus logo aesthetic." \
  --reference assets/groktopus-logo-vintage.png \
  --aspect landscape \
  --pad \
  --quality high
```

### Method 5: Brand Reference Documentation

For comprehensive brand reference (strategy, visual identity, voice, brand card), use the structured markdown docs in the vault at `99/Groktopus Brand/`:

- [[Groktopus Brand Strategy]] — positioning, personality, competitive landscape
- [[Groktopus Visual Identity]] — full color palette, typography, logo variants, cover standards
- [[Groktopus Voice]] — tone matrix, vocabulary, copy examples
- [[Groktopus Brand Card]] — condensed one-page summary

These are more accurate and complete than AI-generated brand system sheets. The text-to-image prompt approach (previous version of this method) cannot reliably render specific hex values or typeface specimens.

### Method 6: Cover Image Migration (Edit Existing Covers into Brand Style)

When migrating existing article covers from the old painterly watercolor style to the new vintage steel engraving brand identity, use the edit API with the existing cover image as the **source image to edit**. The prompt directs the API to redraw the uploaded image — it does not generate from description alone.

```bash
python3 scripts/generate-with-ref.py \
  --prompt "Redraw this image as a vintage steel engraving. Keep the exact same composition, subjects, and arrangement. Render everything in fine cross-hatched ink linework on warm cream parchment background (#e8d9c0). Use deep maroon ink (#65413a) for all linework and shadows. Use navy (#132345) for structural contrast. Light sources become regions of lighter cross-hatching revealing the parchment beneath. Glowing displays become sparse constellations of fine navy dots. The overall effect should look like a page from an 1850s scientific journal — hand-engraved, scholarly. No colors other than parchment, maroon ink, and navy accents. No text, no lettering, no logos." \
  --reference /path/to/current-cover.png \
  --aspect landscape \
  --quality high \
  --output ~/Downloads/groktopus-cover-slug-etching.png
```

**What works:** Composition is preserved (same figures, same positions). Rendering converts to engraved/etched linework. Background shifts to warm parchment. The uploaded image IS the source — the prompt describes what to change, not a new scene.

**What's approximate:** Ink color comes out as warm dark brown (~#4a3833) rather than exact maroon hex (#65413a). The edits endpoint approximates rather than matches precise brand hex values — close enough for the intended vintage effect. Fine facial detail may simplify — etching trades photographic precision for engraved texture.

**Upload + swap workflow:** Download feature_image → run edit API → upload result to Ghost CDN → update article's feature_image via Admin API.

### Method 7: Site Banner / Cover Image (Already Deployed)

The site-wide `cover_image` is already set on groktop.us (Michelangelo-inspired Creation of Adam with robot/android reaching toward a giant octopus). If it needs replacement in the future:

1. Generate via text-to-image with the brand prompt structure from the cover prompt templates above. Keep the composition: robot/android left, octopus right, fingertip gap.
2. Upload to Ghost CDN via Admin API.
3. **API limitation:** Ghost API tokens cannot update the `cover_image` setting — returns 403. After uploading, set it manually in Ghost Admin → Settings → Brand → Site cover.

---

## Meme Adaptations / Brand Parody

The Groktopus brand's anachronistic identity — a 19th-century steel engraving octopus with an exposed brain — naturally lends itself to adaptation of internet meme formats. The tension between the scholarly etching aesthetic and the lowbrow digital source material is itself the joke.

### When Text in Images Is Allowed

The "no text on covers" hard rule applies to **article cover images only**. Meme and parody illustrations are a deliberate carve-out where branded text is part of the format:

- **Thought bubbles** in fine navy dotted lines, with Bodoni-style navy serif lettering inside
- **Panel labels** (Bodoni-style navy serif under each panel in multi-frame layouts)
- **Navy engraved lettering** in small cartouches at the edge of the frame
- Text must always be in brand-appropriate navy Bodoni-style serif — never Impact, Comic Sans, or modern display fonts. The lettering should look engraved, not overlaid.

### Meme Formats That Work

| Format | Description | Brand fit | Best for |
|--------|-------------|-----------|----------|
| **Galaxy Brain** | 4-panel progression with increasingly complex brains | Natural fit — the octopus already has an exposed brain | AI model evolution, org maturity progression, insight escalation |
| **This Is Fine** | Octopus calmly at desk while flames encroach from edges | Encroaching negative space as fire is visually striking | Enterprise fire drills, burnout, deployment risk, vendor lock-in |
| **Distracted Boyfriend** | Octopus reaching back while looking forward | Strong for comparison or critique pieces | Old stack vs new tool, hype-driven adoption |
| **Two Wolves Inside** | Two octopuses facing each other, human between | Maps to "human-led" brand positioning | Tension between builder and destroyer impulses of AI |
| **They Don't Know** | Octopus with knowing side-eye, failed leadership in background | Analytical register — the octopus sees the structural flaw | First-principles critique, governance analysis |

### Composition Patterns

**Galaxy Brain (4-panel horizontal strip):**
- Each panel framed by thin navy rules, warm parchment background
- Small Bodoni-style navy label in a cartouche beneath each panel (e.g., "CHATGPT" → "CLAUDE" → "OPENCLAW" → "HERMES AGENT")
- Panels progress: simple brain with few folds → elaborated lobes with cross-hatching → transparent cranium with constellation dots → full galaxy nebula brain with cosmic depth
- All in maroon cross-hatching with navy accents — reads like a scientific atlas documenting the evolution of a species

**This Is Fine (single scene):**
- Octopus at a wooden desk center-frame, completely composed, exposed brain neutral
- Flames as encroaching navy and maroon negative-space cross-hatching from all edges
- Thought bubble in fine navy dotted lines above the head: "This Is Fine" in Bodoni-style navy serif
- Tentacles typing at a glowing terminal, coffee cup still full beside one tentacle
- The gag is the contrast between analytical calm and consuming disaster

### Tentacle Physics in Busy Compositions

When the scene has multiple objects (desks, terminals, coffee cups, papers), AI image models frequently draw tentacles passing **through** solid objects — a common failure mode that requires explicit spatial language to avoid:

- Describe each tentacle's spatial layer individually: "Two tentacles rest ON the desk surface typing... One tentacle holds a coffee cup ON the desk to the left — the cup is between tentacle tip and desk surface... One tentacle curls loosely at the octopus's side"
- Use explicit depth-plane language: "positioned ON the desk surface," "hanging naturally from the body," "clear separation from solid objects"
- Keep interactive objects to 3-4 max per scene when tentacles are in motion
- Avoid tentacles that pass both behind and in front of objects in the same frame — pick one depth plane per tentacle

---

All colors come from the single parchment-mode palette. No dark mode, no light mode.

| Element | Hex | Usage |
|---------|-----|-------|
| Parchment (bg) | `#e8d9c0` | Page background |
| Card Surface | `#f0e6d4` | Card backgrounds |
| Hover Surface | `#dac8a8` | Hover states |
| Border | `#c9b89a` | Card borders, dividers |
| Primary Text | `#132345` | Navy body text |
| Secondary Text | `#4a4f63` | Muted text, metadata |
| Accent Maroon | `#65413a` | Links, tags, buttons |
| Accent Amber | `#8e7353` | Hover highlights |
| Gradient start | `#65413a` | Maroon edge |
| Gradient mid | `#8e7353` | Amber center |
| Gradient end | `#132345` | Navy edge |

---

## Brand Compliance Checklist

- [ ] If canonical logo variant used: maroon (`#65413a`) octopus on parchment (`#e8d9c0`) with navy (`#132345`) text
- [ ] If using the circular badge logo: exposed brain is visible and distinguishable from the mantle
- [ ] If using the circular badge logo: "GROKTOPUS" arches along the top in high-contrast serif (Bodoni/Didot style)
- [ ] If using the logo on dark backgrounds: use the inverted variant (parchment/white illustration on navy background)
- [ ] Never separate the octopus mark from the "GROKTOPUS" wordmark
- [ ] Never crop or reshape the circular badge format
- [ ] No outlines, shadows, or effects applied to the logomark
- [ ] Typography is anchored in high-contrast serif for brand communications — not sans-serif, not geometric
- [ ] If cover image: vintage steel engraving style — warm parchment background, maroon cross-hatching, navy accents
- [ ] If cover image: no text, no logos, no generic AI clichés
- [ ] If cover image: covers at least one human subject in a professional interior (not outdoors, not abstract)
- [ ] If cover image: vibe is dramatic/uneasy, not cozy-academic — chiaroscuro lighting, high-stakes mood
- [ ] Overall impression: analytical, authoritative, deep — a publication that reads, not a product that sells
- [ ] The anachronistic choice (vintage etching logo, 18th-century typeface) is deliberate — don't modernize away the character

---

## Prompt Engineering Gotchas

| Problem | Cause | Fix |
|---------|-------|-----|
| **Octopus brain looks like a hat** | The model doesn't understand exposed-brain anatomy in logo format | Specify "cross-section of brain with cortical folds, grid-like pattern, resting on top of the head between the eyes — distinguishable from the mantle" |
| **Tentacles look like snakes** | Models default to snake-like tentacle shapes | Specify "thick rounded tentacles with suction cups along the underside, curling symmetrically" |
| **Logo text unreadable** | Arching text at small sizes renders as gibberish | For small-format logos, generate the octopus-mark-only (no text) and add typography in post-processing |
| **Cover image moderation blocks** | Words like spill, chaos, fragmented, avalanche, buried trigger OpenAI moderation | Use neutral alternatives — pool (not spill), extensive (not avalanche), soft geometric shapes (not fragmented) |
| **Wrong ethnicity in figures** | Model defaults to generic when not specified | Always explicitly describe age, gender, and cultural background of any human figures |
| **Corporate-brochure look** | Models default to clean corporate style without direction | Explicitly specify "vintage steel engraving, 19th-century scientific etching, fine cross-hatched linework on warm parchment — not modern corporate illustration" |
| **Octopus looks threatening** | Octopus imagery defaults to monstrous/alien | Specify "analytical, intelligent, curious — not threatening. The brain signals intellect, not menace." |
| **Tentacles pass through solid objects** | Models don't reason about physics across tentacle+object interactions in busy scenes | Explicitly describe each tentacle's spatial layer — "ON the desk surface," "hanging at the side," "between cup and surface." Keep interactive objects to 3-4 max. Separate tentacles into clear depth planes. |

---

## Inline Illustrations & Data Visualization

Inline diagrams, charts, and figures used within articles follow the same vintage steel engraving brand identity as covers and logos. They should feel like plates in a 19th-century statistical atlas — hand-engraved, scholarly, precise.

### Visual Language

| Element | Specification |
|---------|--------------|
| **Background** | Warm parchment (`#e8d9c0`) — always, never dark |
| **Primary lines** | Maroon ink (`#65413a`) — cross-hatched fills, outlines |
| **Labels & accents** | Navy (`#132345`) — all text, axis labels, arrows |
| **Secondary lines** | Border grey (`#454f62`) — grid lines, scale ticks |
| **Fill pattern** | Cross-hatching or stippling — never solid fills, never gradients |
| **Borders** | Thin navy line with optional decorative corner flourishes |
| **Typography** | Classic serif (Bodoni/Didot style), navy ink — readable at text size |
| **Technique** | Simulated steel engraving — fine linework, no 3D, no glossy effects |

### Chart Type Templates

- **Bar charts** — horizontal bars of dense cross-hatched maroon ink. Axis labels in navy serif. Highest value may be accented with stippled navy dots.
- **Decision / Framework diagrams** — triangular, circular, or matrix layouts. Nodes and connectors in fine maroon linework. Dotted navy lines for relationships.
- **Process / Cycle diagrams** — circular arrangement of stages connected by navy dotted arrows with serif arrowheads. Critical zones shaded with denser hatching.
- **Comparison diagrams** — side-by-side panels separated by a vertical dividing line. Positive scenarios use warm hatching and dotted connections; negative scenarios use dense dark hatching and fading outlines.
- **Timeline / Progression diagrams** — horizontal left-to-right along a navy dotted arrow. Stages as progressively larger circles with growing hatching density.

### Hard Rules

- **No 3D effects, gradients, or glossy fills** — all fills rendered as cross-hatching or stippling
- **No modern chart elements** — no pie wedges, exploded views, or bevel effects
- **Parchment background on ALL inline diagrams** — never dark mode for inline figures
- **Bodoni/Didot-style serif for all labels** — no sans-serif, no system fonts
- **Thin navy border framing** — every diagram is a contained plate
- **Data must be legible first** — the brand style never obscures the information

---

## Reference Images

This skill ships reference images in `assets/`, generated via the image edit API with the canonical logo as input:

| File | Source | Type | Use |
|------|--------|------|-----|
| `assets/groktopus-logo-vintage.png` | AI-generated (text-to-image) | 1024×1024 | **Canonical logo** — maroon octopus with exposed brain on warm parchment, navy "GROKTOPUS" in high-contrast serif |
| `assets/groktopus-brand-card.png` | AI-generated (image edit API, using logo as reference) | 1536×1024 | **Brand reference card** — canonical logo preserved via edit API, with color palette swatches (Parchment #e8d9c0, Maroon Ink #65413a, Navy #132345, Border Grey #454f62), Bodoni/Didot-style serif typography, and tagline |
| `assets/groktopus-cover-001.png` | AI-generated (text-to-image) | 1536×1024 | Strategy session — five diverse professionals around a table reviewing blueprints. Collaborative, analytical, high-stakes decision-making. |
| `assets/groktopus-cover-002.png` | AI-generated (text-to-image) | 1536×1024 | Burnout at scale — vast auditorium with bowed heads, laptops, infinity symbols. Workforce exhaustion, the human cost of transformation. |
| `assets/groktopus-cover-003.png` | AI-generated (text-to-image) | 1536×1024 | Founder critique — commanding foreground figure overlooking rows of human-and-robot workers receding into mist. Structural critique of optimization harm. |
| `assets/groktopus-cover-004.png` | AI-generated (text-to-image) | 1536×1024 | The weight of a decision — single Black woman figure silhouetted in vast empty boardroom at dusk, hand on empty chair. Contemplative stillness after a choice. |
| `assets/groktopus-cover-005.png` | AI-generated (text-to-image) | 1536×1024 | Human-AI collaboration — person at desk with luminous data-form collaborator made of constellation dots. Hopeful, grounded, intellectually alive. |
| `assets/groktopus-inline-001.png` | AI-generated (text-to-image) | 1536×1024 | Inline bar chart — enterprise AI automation percentages across four companies. Cross-hatched maroon bars on parchment. |
| `assets/groktopus-inline-002.png` | AI-generated (text-to-image) | 1536×1024 | Inline decision framework — three-axis triangular diagram for Build vs Buy tradeoff. Compass-style indicator. |
| `assets/groktopus-inline-003.png` | AI-generated (text-to-image) | 1536×1024 | Inline process cycle — four-stage circular diagram of the AI Enthusiasm Gap. Dotted navy arrows, critical zone shaded. |
| `assets/groktopus-inline-004.png` | AI-generated (text-to-image) | 1536×1024 | Inline comparison — side-by-side "Human + AI Partner" vs "Replace with AI." Hopeful vs critical framing. |
| `assets/groktopus-inline-005.png` | AI-generated (text-to-image) | 1536×1024 | Inline timeline — five-stage AI adoption maturity progression. Growing circles along dotted arrow. |

---

## Analysis Methodology

The brand identity for Groktopus was reverse-engineered from:

1. **CSS variables** extracted from the live groktop.us site — exact color values, font stack, spacing scale, shadow definitions, and the signature gradient.
2. **Logo images** sourced from Podchaser cached media and LinkedIn banner — vintage scientific etching style, circular badge format, octopus-with-brain concept.
3. **Homepage content** — tagline, article categories, brand voice signals from headlines and metadata.
4. **Cover image analysis** from 5 articles on groktop.us — actual live cover images analyzed for composition patterns, subject types, setting preferences, and emotional register (see `references/cover-composition-patterns.md`).
5. **Live article content** — 5+ articles read via groktocrawl to understand the editorial voice, argument structure, and the kind of stories the publication tells.

The brand identity was defined over three sessions (May 24, 2026): logo extraction → brand card generation → cover composition analysis → inline illustration standards → single-mode web migration plan. The old `image-groktopus` skill (painterly watercolor style) was absorbed into this skill and deleted.

---

## Related Skills

- **blog-it** (`skill_view('blog-it')`) — One-shot article orchestrator. Routes groktop.us cover image generation to this skill.

## Reference Files

- `references/linkedin-banner-workflow.md` — LinkedIn banner generation via landscape text-to-image + post-processing crop/resize to 1584×396.
- `references/brand-card-generation-session.md` — Detailed technical notes from the initial brand card generation session, including color extraction methodology, edit API parameters, prompt structure that worked, layout diagram, and moderation sensitivity patterns.
- `references/cover-composition-patterns.md` — Analysis of 5 actual groktop.us cover image composition patterns: strategy session, burnout at scale, founder critique, decision weight, human-AI collaboration. Each with subject, setting, vibe mapping, and article-fit guidance. Use this to select the right composition pattern for a new article before writing the generation prompt.
- `references/meme-composition-patterns.md` — Worked examples of meme adaptations (Galaxy Brain, This Is Fine) with complete prompt templates and tentacle-physics prompt engineering for each.

---

## Presentation Style Guide

The Groktopus brand applied to slide decks. Load the full style guide — voice rules, design tokens, slide architecture, typography scale, reusable assets, and anti-patterns — from `references/presentation-style-guide.md`:

```
skill_view(name="groktopus-branding", file_path="references/presentation-style-guide.md")
```
