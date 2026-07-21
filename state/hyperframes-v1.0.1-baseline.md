---
name: hyperframes
description: Create HTML-based video compositions, animated title cards, social overlays, captioned talking-head videos, audio-reactive visuals, and shader transitions using HyperFrames. HTML is the source of truth for video. Use when the user wants a rendered MP4/WebM from an HTML composition, wants to animate text/logos/charts over media, needs captions synced to audio, wants TTS narration, or wants to convert a website into a video.
version: 1.0.1
author: heygen-com
license: Apache-2.0
platforms: [linux, macos, windows]
prerequisites:
  commands: [node, ffmpeg, npx]
metadata:
  hermes:
    tags: [creative, video, animation, html, gsap, motion-graphics]
    related_skills: [manim-video]
    category: creative
    requires_toolsets: [terminal]
---

# HyperFrames

HTML is the source of truth for video. A composition is an HTML file with `data-*` attributes for timing, a GSAP timeline for animation, and CSS for appearance. The HyperFrames engine captures the page frame-by-frame and encodes to MP4/WebM with FFmpeg.

**Complement to `manim-video`:** Use `manim-video` for mathematical/geometric explainers (equations, 3B1B-style). Use `hyperframes` for motion-graphics, talking-head with captions, product tours, social overlays, shader transitions, and anything driven by real video/audio media.

## When to Use

- User asks for a rendered video from text, a script, or a website
- Animated title cards, lower thirds, or typographic intros
- Captioned narration video (TTS + captions synced to waveform)
- Audio-reactive visuals (beat sync, spectrum bars, pulsing glow)
- Scene-to-scene transitions (crossfade, wipe, shader warp, flash-through-white)
- Social overlays (Instagram/TikTok/YouTube style)
- Website-to-video pipeline (capture a URL, produce a promo)
- **Short vertical sizzle reel / stinger promo** — 9:16 rapid-fire, one-concept-per-card
- Any HTML/CSS/JS animation that must render deterministically to a video file

Do **not** use this skill for:
- Pure math/equation animation (→ `manim-video`)
- **Abstract physics or invisible-phenomenon visualization** where the concept lives in fields, waves, particles, or density distributions that must be *shown* rather than described. HyperFrames is text-on-card motion graphics — it tells viewers about things by putting words on screen. For phenomena where the whole point is seeing something that can't normally be seen (scalar field halos, gravitational wave propagation, quantum wavefunctions, dark matter distributions), the medium works against the message. The viewer reads about the phenomenon instead of experiencing it. These need Manim (procedural math animation), simulation rendering, or particle-based visualization instead.
- Image generation or memes (→ image models)
- Live video conferencing or streaming

## Quick Reference

```bash
npx hyperframes init my-video               # scaffold a project
cd my-video
npx hyperframes lint                        # validate before preview/render
npx hyperframes preview                     # live-reload browser preview (port 3002)
npx hyperframes render --output final.mp4   # render to MP4
npx hyperframes doctor                      # diagnose environment issues
```

Render flags: `--quality draft|standard|high` · `--fps 24|30|60` · `--format mp4|webm` · `--docker` (reproducible) · `--strict`.

Full CLI reference: [references/cli.md](references/cli.md).

## Setup (one-time)

```bash
bash "$(dirname "$(find ~/.hermes/skills -path '*/hyperframes/SKILL.md' 2>/dev/null | head -1)")/scripts/setup.sh"
```

The script:
1. Verifies Node.js >= 22 and FFmpeg are installed (prints fix instructions if not).
2. Installs the `hyperframes` CLI globally (`npm install -g hyperframes@>=0.4.2`).
3. Pre-caches `chrome-headless-shell` via Puppeteer — **required** for best-quality rendering via Chrome's `HeadlessExperimental.beginFrame` capture path.
4. Runs `npx hyperframes doctor` and reports the result.

See [references/troubleshooting.md](references/troubleshooting.md) if setup fails.

## Procedure

> **⚠️ Before writing any composition, read the [Pitfalls](#pitfalls) section below.**
> It documents critical gotchas — standalone HTML files outside `npx hyperframes init`, WAAPI vs GSAP, `gsap.from()` opacity collisions, and more — that `lint` cannot catch and will silently produce unusable video renders.

### 1. Plan before writing HTML

Before touching code, articulate at a high level:
- **What** — narrative arc, key moments, emotional beats
- **Structure** — compositions, tracks (video/audio/overlays), durations
- **Visual identity** — colors, fonts, motion character (explosive / cinematic / fluid / technical)
- **Hero frame** — for each scene, the moment when the most elements are simultaneously visible. This is the static layout you'll build first.

**Visual Identity Gate (HARD-GATE).** Before writing ANY composition HTML, a visual identity must be defined. Do NOT write compositions with default or generic colors (`#333`, `#3b82f6`, `Roboto` are tells that this step was skipped). Check in order:

1. **`DESIGN.md` at project root?** → Use its exact colors, fonts, motion rules, and "What NOT to Do" constraints.
2. **User named a style** (e.g. "Swiss Pulse", "dark and techy", "luxury brand")? → Generate a minimal `DESIGN.md` with `## Style Prompt`, `## Colors` (3-5 hex with roles), `## Typography` (1-2 families), `## What NOT to Do` (3-5 anti-patterns).
3. **User provided a URL with a known visual style** (personal site, brand site, blog)? → Extract the design system from the live site at runtime via `browser_console` with `getComputedStyle` + CSS custom property extraction:
   ```javascript
   JSON.stringify({
     bg: getComputedStyle(document.body).backgroundColor,
     color: getComputedStyle(document.body).color,
     font: getComputedStyle(document.body).fontFamily,
     links: Array.from(document.querySelectorAll('a')).map(a => getComputedStyle(a).color).filter((v,i,a) => a.indexOf(v)===i),
     headingColors: Array.from(document.querySelectorAll('h1,h2,h3')).map(h => getComputedStyle(h).color).filter((v,i,a) => a.indexOf(v)===i)
   })
   ```
   Also fetch the site's main CSS file(s) via `curl` to extract `:root { }` custom property values (colors, fonts, spacing). Map extracted values directly into the composition's CSS. Generate a `DESIGN.md` from the extracted palette for reference. This produces an accurate visual match without asking the user to describe their own site's design.

4. **None of the above?** → Ask 3 questions before writing any HTML:
   - Mood? (explosive / cinematic / fluid / technical / chaotic / warm)
   - Light or dark canvas?
   - Any brand colors, fonts, or visual references?

   Then generate a `DESIGN.md` from the answers. Every composition must trace its palette and typography back to `DESIGN.md` or explicit user direction.

### 2. Scaffold

> **⚠️ CRITICAL: You MUST use `npx hyperframes init` before writing any composition HTML.**
> Do NOT create an `index.html` file by hand outside a scaffolded project. A standalone HTML file cannot be `lint`-ed, `validate`-d, `inspect`-ed, or `render`-ed — it is not a HyperFrames project and cannot produce a video. This rule is non-negotiable. See the [Pitfalls](#pitfalls) section below for details.

```bash
npx hyperframes init my-video --non-interactive
```

Templates: `blank`, `warm-grain`, `play-mode`, `swiss-grid`, `vignelli`, `decision-tree`, `kinetic-type`, `product-promo`, `nyt-graph`. Pass `--example <name>` to pick one, `--video clip.mp4` or `--audio track.mp3` to seed with media.

### 3. Layout before animation

Write the static HTML+CSS for the **hero frame first** — no GSAP yet. The `.scene-content` container must fill the scene (`width:100%; height:100%; padding:Npx`) with `display:flex` + `gap`. Use padding to push content inward — never `position: absolute; top: Npx` on a content container (content overflows when taller than the remaining space).

Only after the hero frame looks right, add `gsap.from()` entrances (animate **to** the CSS position) and `gsap.to()` exits (animate **from** it).

See [references/composition.md](references/composition.md) for the full data-attribute schema and composition rules.

### 4. Animate with GSAP

> **⚠️ Use `gsap.timeline()` only. Do NOT use the Web Animations API (`element.animate()`) or `requestAnimationFrame` — they are incompatible with the HyperFrames capture engine and break deterministic playback.**

Every composition must:
- Register its timeline: `window.__timelines["<composition-id>"] = tl`
- Start paused: `gsap.timeline({ paused: true })` — the player controls playback
- Use finite `repeat` values (no `repeat: -1` — breaks the capture engine). Calculate: `repeat: Math.ceil(duration / cycleDuration) - 1`.
- Be deterministic — no `Math.random()`, `Date.now()`, or wall-clock logic. Use a seeded PRNG if you need pseudo-randomness.
- Build synchronously — no `async`/`await`, `setTimeout`, or Promises around timeline construction.

See [references/gsap.md](references/gsap.md) for the core GSAP API (tweens, eases, stagger, timelines).

### 5. Transitions between scenes

Multi-scene compositions require transitions. Rules:
1. **Always use a transition between scenes** — no jump cuts.
2. **Always use entrance animations** on every scene element (`gsap.from(...)`).
3. **Never use exit animations** except on the final scene — the transition IS the exit.
4. The final scene may fade out.

Use `npx hyperframes add <transition-name>` to install shader transitions (`flash-through-white`, `liquid-wipe`, etc.). Full list: `npx hyperframes add --list`.

For **CSS transitions**, see `references/features.md#scene-transitions` for the full mood/energy table and available techniques (opacity, transforms, `clip-path`, `backdrop-filter` for blur crossfades). The blur crossfade in particular has a 3-phase choreography — blur in → crossfade → blur out — documented with timing guidance in that reference.

### 6. Audio, captions, TTS, audio-reactive, highlighting

- **Audio:** always a separate `<audio>` element (video is `muted playsinline`). For background music (BGM), the element must have **both** an `id` attribute and a `src` attribute directly on the `<audio>` tag — a `<source>` child alone triggers `media_missing_src` at render time:
  ```html
  <audio id="bgm" src="assets/bgm.mp3" data-start="0" data-duration="28.5" data-track-index="0" data-bgm autoplay loop></audio>
  ```
  Royalty-free BGM sources: Pixabay Music (pixabay.com/music), Chosic (chosic.com), ElevenLabs Music (elevenlabs.io/music/lofi). Many lofi/jazz tracks are no-attribution or CC0. Download as MP3, place in `assets/`, reference via `src="assets/file.mp3"`. See the BGM section in [references/vertical-stinger-pattern.md](references/vertical-stinger-pattern.md) for the full integration pattern and linter rules.
- **TTS:** `npx hyperframes tts "Script text" --voice af_nova --output narration.wav`. List voices with `--list`. Voice ID first letter encodes language (`a`/`b`=English, `e`=Spanish, `f`=French, `j`=Japanese, `z`=Mandarin, etc.) — the CLI auto-infers the phonemizer locale; pass `--lang` only to override. Non-English phonemization requires `espeak-ng` installed system-wide.
- **Captions:** `npx hyperframes transcribe narration.wav` → word-level transcript. Pick style from the transcript tone (hype / corporate / tutorial / storytelling / social — see the table in `references/features.md`). **Language rule:** never use `.en` whisper models unless the audio is confirmed English — `.en` translates non-English audio instead of transcribing it. Every caption group MUST have a hard `tl.set(el, { opacity: 0, visibility: "hidden" }, group.end)` kill after its exit tween — otherwise groups leak visible into later ones.
- **Audio-reactive visuals:** pre-extract audio bands (bass / mid / treble) and sample per-frame inside the timeline with a `for` loop of `tl.call(draw, [], f / fps)` — a single long tween does NOT react to audio. Map bass → `scale` (pulse), treble → `textShadow`/`boxShadow` (glow), overall amplitude → `opacity`/`y`/`backgroundColor`. Avoid equalizer-bar clichés — let content guide the visual, audio drive its behavior.
- **Marker-style highlighting:** highlight, circle, burst, scribble, sketchout effects for text emphasis are deterministic CSS+GSAP — see `references/features.md#marker-highlighting`. Fully seekable, no animated SVG filters.
- **Scene transitions:** every multi-scene composition MUST use transitions (no jump cuts). Pick from CSS primitives (push slide, blur crossfade, zoom through, staggered blocks) or shader transitions (`flash-through-white`, `liquid-wipe`, `cross-warp-morph`, `chromatic-split`, etc.) via `npx hyperframes add`. Mood and energy tables live in `references/features.md#transitions`. Do not mix CSS and shader transitions in the same composition.

### 7. Lint, validate, inspect, preview, render

```bash
npx hyperframes lint              # catches missing data-composition-id, overlapping tracks, unregistered timelines
npx hyperframes validate          # WCAG contrast audit at 5 timestamps
npx hyperframes inspect           # visual layout audit — overflow, off-frame elements, occluded text
npx hyperframes preview           # live browser preview
npx hyperframes render --quality draft --output draft.mp4    # fast iteration
npx hyperframes render --quality high --output final.mp4     # final delivery
```

`hyperframes validate` samples background pixels behind every text element and warns on contrast ratios below 4.5:1 (or 3:1 for large text). `hyperframes inspect` is the layout-side companion — runs the page at multiple timestamps and flags issues that a static lint can't see (a caption that wraps past the safe area only at 4.5s, a card that overflows when its title is the longest variant, an element that ends up behind a transition shader). Run `inspect` especially on compositions with speech bubbles, cards, captions, or tight typography.

### 8. Website-to-video (if the user gives a URL)

Use the 7-step capture-to-video workflow in [references/website-to-video.md](references/website-to-video.md): capture → DESIGN.md → SCRIPT.md → storyboard → composition → render → deliver.

### 9. Vertical / Mobile Compositions (Sizzle Reel / Stinger Style)

For 9:16 portrait compositions with rapid single-concept pacing — see the full pattern guide in [references/vertical-stinger-pattern.md](references/vertical-stinger-pattern.md).

**Key rules for this format:**
- **One concept per clip** — each timed element carries exactly one idea (~8-15 words)
- **3.0-3.5s per card** — enough time to read, not enough to drift
- **Quick crossfades** — 0.35s in / 0.2s out with slight temporal overlap for stinger momentum
- **Total length: 24-30s** for a typical sizzle reel (6-8 segments)
- **No walls of text** — if a card needs more than ~15 words, split into two cards
- **Every word earns its place** — on a 3.5s card, each word competes for attention
- **Fill the frame** — on a phone screen, text below 48px at 1080p becomes unreadable at arm's length. Body text should be 56-64px, labels 20-24px. Padding should be 50-60px, not 80-100px. The canvas is 1080px wide — use it. Liminal space kills mobile readability.
- **Line breaks are design choices** — 2 vs 3 lines creates different reading dynamics
- **One accent-color word per card** — creates visual hierarchy, a landing point for the eye
- **Pipeline cards need +0.5s** — the viewer has to parse structure, not just read text
- **CTA must be specific** — a concrete command or URL beats "Learn more"
- **Hook Build Proof CTA** — even a 28s reel needs narrative shape
- **All existing rules apply** — deterministic, paused, registered timelines

The vertical-stinger-pattern reference includes timing templates, a verified 28s example, and the fade-in/out helper functions used in production.

### 10. Blog Companion Explainer Videos (if the article has a visual concept)

If a blog article has a concept that benefits from visual animation (orbits, growth, scale comparisons, processes), see [references/blog-companion-explainer.md](references/blog-companion-explainer.md) for a 10-15s single-concept explainer workflow. Includes visual identity extraction from the target site, PeerTube upload, and the three-part explainer structure (title → animated concept → punchline).

## Pitfalls

- **`HeadlessExperimental.beginFrame' wasn't found`** — Chromium 147+ removed this protocol. Ensure you're on `hyperframes@>=0.4.2` (auto-detects and falls back to screenshot mode). Escape hatch: `export PRODUCER_FORCE_SCREENSHOT=true`. See [hyperframes#294](https://github.com/heygen-com/hyperframes/issues/294) and [references/troubleshooting.md](references/troubleshooting.md).
- **System Chrome (not `chrome-headless-shell`)** — renders hang for 120s then timeout. Run `npx puppeteer browsers install chrome-headless-shell` (setup.sh does this). `hyperframes doctor` reports which binary will be used.
- **`repeat: -1` anywhere** — breaks the capture engine. Always compute a finite repeat count.
- **`gsap.set()` on clip elements that enter later** — the element doesn't exist at page load. Use `tl.set(selector, vars, timePosition)` inside the timeline instead, at or after the clip's `data-start`.
- **`<br>` inside content text** — forced breaks don't know the rendered font width, so natural wrap + `<br>` double-breaks. Use `max-width` to let text wrap. Exception: short display titles where each word is deliberately on its own line.
- **Animating `visibility` or `display`** — GSAP can't tween these. Use `autoAlpha` (handles both visibility and opacity).
- **Calling `video.play()` or `audio.play()`** — the framework owns playback. Never call these yourself.
- **Building timelines async** — the capture engine reads `window.__timelines` synchronously after page load. Never wrap timeline construction in `async`, `setTimeout`, or a Promise.
- **Standalone `index.html` wrapped in `<template>`** — hides all content from the browser. Only **sub-compositions** loaded via `data-composition-src` use `<template>`.
- **Writing a standalone HTML file outside the `npx hyperframes init` project structure.** A valid HyperFrames HTML file is NOT a complete HyperFrames project. Without `npx hyperframes init`, there is no `hyperframes.json` config, no `compositions/` directory, no `assets/` directory, and — critically — no way to run `lint`, `validate`, `inspect`, or `render`. A standalone HTML file can only be previewed in a browser; it cannot produce a video file. The scaffold → compose → lint → validate → inspect → render pipeline is the mandatory workflow. Never write an `index.html` for HyperFrames outside a scaffolded project.
- **Using Web Animations API (WAAPI) or `requestAnimationFrame` instead of GSAP.** HyperFrames compositions must use GSAP's `gsap.timeline()` as the sole animation engine. WAAPI and RAF-based timelines are not compatible with the capture engine, break deterministic playback, and cannot be linted or validated. If you find yourself writing `element.animate()` or `requestAnimationFrame`, switch to GSAP.
- **Using video for audio** — always muted `<video>` + separate `<audio>`.
- **Process-flow animations must move elements, not just change text.** When illustrating a process where components move between states (cards across kanban columns, nodes through a pipeline, items along an assembly line), the animated elements must actually change position. Animating text content in place — fading one label out and another in on a fixed board — does not convey process motion; the viewer sees text flickering, not items progressing. Use `gsap.to()` to translate elements between screen positions, or tween `x`/`y`/`top`/`left` to show movement across the layout. If the visual metaphor is cards traveling through columns, the cards must actually move between column positions. A static board with changing labels is a slideshow, not a process animation.
- **`media_missing_id` — audio element needs id attribute** — `<audio>` elements with `data-start` trigger this lint error if they lack an `id`. The renderer requires `id` to discover media elements; without it, audio is silent in renders. Always add `id="descriptive-name"` to every `<audio>` and `<video>` element.
- **`media_missing_src` — put src on the audio element itself, not just in a <source> child** — The renderer reads `src` from the parent `<audio>` tag, not from nested `<source>` elements. Always add `src="assets/file.mp3"` directly on the `<audio>` tag. A `<source>` child alone will render silent video.
- **Non-deterministic font (font family name not in deterministic map)** — The compiler prints `No deterministic font mapping for: <font>` when a font family isn't in its alias map (Monaco, system fonts, etc.). It falls back to a similar mapped font, which may change the visual result. To guarantee exact font rendering: use a mapped font name from the compiler's alias list, or add a local `@font-face` declaration with a hosted/local font file, or install the font on the render machine (Docker: add to Dockerfile). The compiler prints its full alias map at render time.
- **Skipping the verification pipeline before delivering.** Validate, inspect, and visual frame extraction are not optional. A render that succeeds (`exit 0`) can still produce unreadable output (low contrast, tiny text, rendering artifacts, offscreen elements). The most common failure pattern: rendering, uploading to a platform, and embedding — all without ever looking at a single frame. Run `npx hyperframes validate` for contrast audit, `npx hyperframes inspect` for layout/overflow, and extract a mid-composition frame (`ffmpeg -i final.mp4 -ss 00:00:05 -vframes 1 preview.png`) before any upload. If the preview frame doesn't look good at a glance, the video is not ready.
- **Rendering and delivering without a visual frame check.** `ffprobe` telling you the duration is correct does not mean the video is watchable. Always extract a mid-composition frame and inspect it — text readability, contrast, element positions, color accuracy. A 30-second render time saving is not worth shipping a video where the text is illegible against the background. The Verification section details this; follow it before every delivery.
- **Missing `class="clip"` on timed elements.** Every HTML element with `data-start` and `data-duration` attributes must have `class="clip"` for the HyperFrames runtime to control its visibility. Without it, the element stays visible for the entire composition regardless of its timing window. The lint catches this but it's easy to miss when writing compositions quickly — always add `class="clip"` as part of the element definition, not as an afterthought.
- **Overlapping clips on the same track.** Two clips with the same `data-track-index` whose time windows overlap cause rendering conflicts. Each clip on a shared track must have non-overlapping time ranges. Use unique `data-track-index` values for clips that need to be visible simultaneously (e.g. background + foreground + labels). Use staggered `data-start`/`data-duration` for clips on the same track. The lint's `overlapping_clips_same_track` error is a hard gate — do not render until it's resolved.
- **Foreground clips rendered behind background clips (z-index occlusion).** Clips on different tracks that share the same screen space (e.g. text labels over a video, a scale bar over an animation) can render in the wrong visual order even when their track indices are distinct. The issue is clip-level z-index: HyperFrames positions clips in the render DOM in source order, so an `<img>` or `<video>` clip later in the HTML can stack on top of a text clip defined earlier, even if the text `data-track-index` is higher. **Fix:** explicitly set `position: relative; z-index: N` (N >= 10) on foreground clips (text overlays, labels, end cards) and `z-index: 1` or no z-index on background clips. Test by extracting a mid-composition frame before rendering — if you can see the background but not the label, z-index is the culprit. Common pattern: a background video animation + centered title text + scale bar labels + ending text all need distinct z-index values to stack correctly.
- **`gsap.from()` with CSS already at start value.** If your CSS sets `opacity: 0` (or any property) on an element, and you also pass that same value in `gsap.from()`, GSAP animates *from* that value *to* the CSS value — which is the same — so the element stays invisible. The fix: either set CSS `opacity: 1` (or omit the property) and let `gsap.from()` define the starting state, or use `gsap.fromTo()` with explicit start and end values. This is especially easy to hit with `opacity: 0` in CSS for clips that should appear mid-timeline — the gsap.set at timePosition pattern works fine, but a `gsap.from({opacity: 0})` on the same element will produce no visible animation.

## Verification

Before and after rendering:

1. **Lint + validate + inspect pass:** `npx hyperframes lint --strict && npx hyperframes validate && npx hyperframes inspect` (lint catches structural issues, validate catches contrast, inspect catches visual layout / overflow issues — see troubleshooting.md if warnings appear).
2. **Animation choreography** — for new compositions or significant animation changes, run the animation map. `npx hyperframes init` copies the skill scripts into the project, so the path is project-local:
   ```bash
   node skills/hyperframes/scripts/animation-map.mjs <composition-dir> \
     --out <composition-dir>/.hyperframes/anim-map
   ```
   Outputs a single `animation-map.json` with per-tween summaries, ASCII Gantt timeline, stagger detection, dead zones (>1s with no animation), element lifecycles, and flags (`offscreen`, `collision`, `invisible`, `paced-fast` <0.2s, `paced-slow` >2s). Scan summaries and flags — fix or justify each. Skip on small edits.
3. **File exists + non-zero:** `ls -lh final.mp4`.
4. **Duration matches `data-duration`:** `ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 final.mp4`.
5. **Visual check:** extract a mid-composition frame: `ffmpeg -i final.mp4 -ss 00:00:05 -vframes 1 preview.png`.
6. **Audio present if expected:** `ffprobe -v error -show_streams -select_streams a -of default=nw=1:nk=1 final.mp4 | head -1`.

If `hyperframes render` fails, run `npx hyperframes doctor` and attach its output when reporting.

### 10. Blog Companion Explainer Videos

For 10-15s single-concept explainer videos to accompany blog articles — see the full pattern guide in [references/blog-companion-explainer.md](references/blog-companion-explainer.md). This workflow extracts the article's visual identity from the site CSS, builds a 3-part structure (title card → animated concept → punchline), and handles PeerTube upload.

**Use when:** an article has a concept that benefits from visual animation (spatial, temporal, comparative) and the user asks for a companion video. Not for standalone sizzle reels (use Step 9) or full website captures (use Step 8).

## References

- [composition.md](references/composition.md) — data attributes, timeline contract, non-negotiable rules, typography/asset rules
- [cli.md](references/cli.md) — every CLI command (init, capture, lint, validate, inspect, preview, render, transcribe, tts, doctor, browser, info, upgrade, benchmark)
- [gsap.md](references/gsap.md) — GSAP core API for HyperFrames (tweens, eases, stagger, timelines, matchMedia)
- [features.md](references/features.md) — captions, TTS, audio-reactive, marker highlighting, transitions (load on demand)
- [website-to-video.md](references/website-to-video.md) — 7-step capture-to-video workflow
- [troubleshooting.md](references/troubleshooting.md) — OpenClaw fix, env vars, common render errors
- [vertical-stinger-pattern.md](references/vertical-stinger-pattern.md) — 9:16 mobile sizzle reel composition pattern (one-concept-per-card, stinger timing, verified example)
- [background-music.md](references/background-music.md) — sourcing royalty-free BGM, audio element requirements, volume control via FFmpeg, genre mood table
- [blog-companion-explainer.md](references/blog-companion-explainer.md) — 10-15s single-concept explainer for blog articles, site CSS extraction, PeerTube upload
