---
name: image-magnus919
description: Generate hero images for magnus919.com blog articles in the signature gonzo-illustration style — frantic dip-pen linework, ink splatter, ANSI accent colors on warm parchment ground. Saves to Downloads (standalone) or directly to the Hugo repo (when used in the blog-it pipeline).
version: 1.0.0
---

# image-magnus919 — Blog Hero Image Generator

## When to Use

When the user asks for an image for magnus919.com — blog hero images, article headers, visual metaphors for long-form essays. Only use for magnus919.com content (personal/intellectual blog); not for rdumesh.org, groktop.us, or southeastme.sh.

## The Fixed Template

This style is **locked** — do not alter it. The only variable is `[SUBJECT]`.

```
Generate a hero image for a blog article.

Landscape composition, 16:9. Mixed-media gonzo illustration — frantic dip-pen linework with violent variation in weight, lines that overshoot corners and never quite close, frenzied crosshatching that builds into dark masses. Ink blots and aggressive splatter that feel like the pen slipped and it improved the image. Every element in the scene is rendered with the same gestural urgency — nothing is allowed to look realistic or grounded, mundane objects are just as distorted and alive as surreal ones, anatomy is wrong in ways that feel intentional, perspective defies itself, ordinary things look like they are in the middle of becoming something else.

Color palette built on a warm parchment ground (#eceae5). Amber (#d29d00) as the signature highlight and focal glow — concentrated warmth at the emotional center. ANSI accent colors given real presence: muted brick red (#d75f5f), sage green (#87af87), faded denim blue (#87afd7), dusty magenta (#af87af), oxidized cyan (#5fafaf), hot-yellow flares (#ffd700). Deep burnt-umber (#1a170f) for heavy ink masses, shadows, and grounding edges. Colors bleed and pool like diluted ink wash on absorbent paper, bleeding past their outlines.

Mood: the entire scene exists in a state of controlled delirium. Nothing is stable. The surreal and the mundane are indistinguishable from each other. Analog and digital eras collide without acknowledging the contradiction. The image feels like it was drawn by someone who understood the subject too deeply and couldn't stop their hand from showing it.

Texture: heavy watercolor paper grain, aggressive ink splatter, dry brush drags, water blooms, ink bleeds. Nothing is clean. Nothing is quite finished. No text, no UI, no logos.

[SUBJECT: <one line describing what's in the scene>]

--ar 16:9 --no clean lines, vector, 3D render, glossy, neon, photorealistic, digital illustration, smooth, architectural sketch, travel journal, realism, realistic rendering, naturalistic
```

## Workflow

### Step 1: Understand the Article's Core Metaphor

Before writing the SUBJECT line, ask yourself: **what is the central image this article is trying to communicate?** The style is already set — your job is finding the visual metaphor that captures the essay's thesis in one frame.

The best subjects for this style sit at friction points:
- Something mechanical, cognitive, or digital coming apart or transforming
- The collision of analog and digital eras
- A mind in the act of understanding something that resists understanding
- Ordinary objects in states of becoming something else

### Step 2: Write the SUBJECT

Keep the SUBJECT to **one line** describing what's in the scene. Be concrete about what elements are present, but don't describe the style — the template handles that. Examples:

- ✓ "A human figure seated in a straight-backed chair, concentric spirals of ink and amber light folding above their head, the room dissolving at the edges"
- ✓ "An old wooden desk at the boundary between a forest floor and a data center, half-rotted wood and half-server rack, coffee liquid defying gravity"
- ✓ "Two empty wooden chairs facing each other, the space between them filled with a storm of tangled ink threads and fragments of dialogue"
- ✗ "A man thinking" (too vague — nothing concrete to render)
- ✗ "A beautiful surreal landscape with warm colors" (missing the friction point)

**SUBJECT validation checklist — before constructing the full prompt, verify:**

1. **Concrete elements.** Specific objects, positions, relationships ("a wooden chair," not "furniture"). The reader should be able to picture each element. The more specific, the better — rich subjects produce covers that reward a second look.
2. **Friction point present.** Does the scene capture something coming apart, transforming, or colliding? If the answer is no, revise.
3. **No style words.** The template handles style. Your SUBJECT describes WHAT is in the scene, not how it looks. No "chaotic," "frenetic," or "dreamlike" in the SUBJECT line.
4. **Check anatomy for living subjects.** If the subject includes an animal or person, verify structural accuracy before finalizing (e.g., for jumping spiders: two visible eyes per side).

### Step 3: Generate the Image

**Path A — No source photo (default):** Use the `image_generate` tool with `aspect_ratio: landscape`, assembling the full prompt as:

```
[Full template with SUBJECT filled in]
```

**Path B — Reference image available (any subject):** Use the OpenAI `/v1/images/edits` endpoint. This feeds the actual image into the model rather than describing the subject from text, producing a far more faithful composition. This is the CORRECT approach whenever a reference image exists — the user explicitly corrected (May 2026) that `image_generate` is the wrong tool for this.

**Path B Quick Reference — follow these steps in order:**

1. **Crop reference to 1024x1024 square** — min dimension, center crop. Save to `/tmp/gonzo_source.png`.
2. **Extract API key** — use Python grep from `~/.hermes/.env`. Do NOT use `source ~/.hermes/.env` (malformed lines cause exit 127).
3. **Request landscape output** — use `size=1792x1024`. If the API rejects this size (some models only support square), fall back to `size=1024x1024` and accept square output.
4. **Do NOT include `response_format`** — the edits API returns a 400 error for this parameter. Omit it entirely.
5. **Set generous timeout** — `--max-time 300` with curl or `timeout=300` with Python requests. The API regularly takes 30-120s.
6. **Convert output** — if the API returns `b64_json`, decode and save as PNG. If it returns a URL, download it. Then convert to 1600px JPEG Q85.

Required: `OPENAI_API_KEY` must be configured in `~/.hermes/.env`.

IMPORTANT — .env sourcing pitfall: `~/.hermes/.env` has malformed lines that cause `set -e` scripts (including bash scripts with `source ~/.hermes/.env`) to exit with code 127. Extract the key via grep/sed instead:

```bash
OPENAI_KEY=$(grep '^OPENAI_API_KEY=*** ~/.hermes/.env | sed 's/^OPENAI_API_KEY=*** | sed 's/["'"'"']//g')
```

Or in Python:
```python
with open(os.path.expanduser("~/.hermes/.env")) as f:
    for line in f:
        if line.startswith("OPENAI_API_KEY=***             key = line.split("=", 1)[1].strip("\"'")
```

**Edits API recipe (landscape output, preferred for covers):**

The edits API accepts landscape sizes. For blog covers, use `size=1792x1024` to get a native 16:9 landscape image at high resolution.

```bash
# 1. Crop source to square and resize to 1024x1024
python3 -c "
from PIL import Image
img = Image.open('SOURCE_PATH')
size = min(img.size)
left = (img.size[0] - size) // 2
top = (img.size[1] - size) // 2
img_sq = img.crop((left, top, left + size, top + size))
img_sq = img_sq.resize((1024, 1024), Image.LANCZOS)
img_sq.save('/tmp/gonzo_source.png', 'PNG')
"

# 2. Call the edits endpoint with LANDSCAPE size
curl -s --max-time 300 https://api.openai.com/v1/images/edits \
  -H "Authorization: Bearer *** \
  -F "model=gpt-image-2" \
  -F "image=@/tmp/gonzo_source.png" \
  -F "prompt=Transform this image into a gonzo illustration — [describe the scene in gonzo terms]" \
  -F "n=1" \
  -F "size=1792x1024" 2>&1 | python3 -c "
import sys, json, base64
data = json.load(sys.stdin)
b64 = data['data'][0].get('b64_json', data['data'][0].get('url'))
if isinstance(b64, str) and b64.startswith('http'):
    print(b64)
else:
    with open('/tmp/gonzo_result.png', 'wb') as f:
        f.write(base64.b64decode(b64))
    print('/tmp/gonzo_result.png')
"
```

**Important edits API behaviors:**
- **Landscape output is better for covers.** The API natively accepts `1792x1024` (17:10 ≈ 16:9). This gives a full landscape cover at native resolution. Resize down to 1600x914 JPEG Q85 — that's a DOWNSCALE (1792→1600 = -11%), so no quality loss. Tested and confirmed working (May 2026).
- **`size=1792x1024` may be rejected by some models** (dall-e-2, older gpt-image-2 versions). If you get a 400 error about size, fall back to `size=1024x1024` square. Do NOT crop square output to 16:9 and upscale — that creates visible artifacts.
- **`response_format` is NOT supported** by the edits API. Sending `"response_format": "b64_json"` returns a 400 error. Omit this parameter entirely.
- **API key redaction in tool output** — the terminal tool's security layer may replace the key with `*** in curl commands before they reach the API. Workaround: pass the key via a Python script that reads from `~/.hermes/.env` directly, avoiding shell variable interpolation.
- **Do NOT use square output for covers.** Cropping 1024x1024 to 16:9 and upscaling to 1600px creates visible artifacts — the user corrected this as making the image look "crap." If you must use square (e.g., for portrait mode), accept the square aspect ratio at 1024x1024 or native. Do not crop and upscale.
- Takes 30-120+ seconds. Always use `--max-time 300` with curl or `timeout=300` with requests.
- Usually returns `b64_json` (base64-encoded PNG), not a URL.
- See `scripts/gonzo-convert.py` for a full Python implementation that handles key extraction, cropping, API call, and saving.

**When to choose Path B over Path A:**
- A reference image exists — whether a person, scene, or object. The user explicitly corrected (May 2026) that the edits endpoint is the CORRECT approach for reference-based conversions. Do NOT use Path A or Path C when a reference image is available.
- The subject's likeness, composition, or positioning from the reference matters.

**CORRECTION (May 2026): Path C is not preferred.** In a prior version of this skill, Path C described using `vision_analyze` to describe a reference image and then generating via `image_generate`. The user explicitly corrected this: "image_generate is the WRONG tool. You need to be uploading to the image_edit endpoint with reference images." When a reference image exists, use Path B (edits API) — not a text description fed to `image_generate`.

### Iterative Refinement (Edits API for Corrections)

When a text-to-image generation is 90% right but one element is wrong (wrong object in hand, missing detail, incorrect accessory), **do not regenerate from scratch.** Use the edits API with the first-generation image as the source to surgically fix the specific element while preserving everything else. This is different from Path B (style conversion of reference photos) — this is correcting your own generated output.

The pattern: crop the generated image to 1024x1024 square, call the edits API with `size=1792x1024`, and use a prompt that explicitly says what to KEEP and what to CHANGE. See `references/edits-api-iterative-refinement.md` for the full workflow, including a real worked example.

Maximum 1-2 refinement cycles before the image drifts. If the second edit still misses, regenerate from scratch with a better initial prompt rather than chasing with more edits.

Path A (text-to-image) remains correct when NO reference image exists at all — pure conceptual generation from scratch.

### Step 4: Save the Image

The `image_generate` tool returns a file at a cache path like `/Users/magnus/.hermes/cache/images/*.png`.

**Standalone mode** (just generating a hero image, no article yet):
Save to Downloads with the naming convention `magnus919-{slug}-hero.png`.

```bash
cp "<cache_path>" "/Volumes/tank01/magnus/Downloads/magnus919-{slug}-hero.png"
```

**Pipeline mode** (part of a blog-it article — slug is known):
Save directly to the Hugo repo as `cover.jpg` inside the post bundle:

```bash
# Save as PNG first (image_generate output)
cp "<cache_path>" "/Volumes/tank01/magnus/git/magnus919.com/content/posts/{slug}/cover.png"

# Resize to 1600px wide and convert to JPEG Q85 for the repo
magick "/Volumes/tank01/magnus/git/magnus919.com/content/posts/{slug}/cover.png" \
  -resize 1600x -quality 85 \
  "/Volumes/tank01/magnus/git/magnus919.com/content/posts/{slug}/cover.jpg"

# Remove the intermediate PNG
rm "/Volumes/tank01/magnus/git/magnus919.com/content/posts/{slug}/cover.png"
```

The repo convention is **cover.jpg at 1600px wide, JPEG Q85**. All covers are displayed at `max-width: 100%` inside an ~820px content area, so 1600px covers the 2x Retina bound. PNG source files are not committed — `cover.jpg` is the canonical format.

If you're not sure which mode, save to Downloads — blog-it can pick it up from there at finalize time.

### Step 4a: Post-Generation Processing (standalone mode)

When saving to Downloads for manual placement, always convert the raw output to the repo standard before committing:

```bash
# Resize to 1600px wide, JPEG Q85
magick "/Volumes/tank01/magnus/Downloads/magnus919-{slug}-hero.png" \
  -resize 1600x -quality 85 \
  "/Volumes/tank01/magnus/Downloads/magnus919-{slug}-hero.jpg"

# Copy into the page bundle
cp "/Volumes/tank01/magnus/Downloads/magnus919-{slug}-hero.jpg" \
  "/Volumes/tank01/magnus/git/magnus919.com/content/posts/{slug}/cover.jpg"
```

### Step 5: Confirm

Tell the user the image is ready and where it was saved. If used in pipeline mode, note that it's already in the repo at `content/posts/{slug}/cover.jpg`. Optionally offer to save the subject choice as a reference for future images.

### Step 6: Integration with blog-it

When `blog-it` is orchestrating the full article pipeline, image generation can happen at two points:
1. **After angle confirmation (earliest)** — the article's core metaphor is clear, so the subject can be chosen and the image generated early
2. **At finalize time** — if no image was generated during drafting, `blog-it` flags it as a gap

The `blog-it` skill handles the repo placement at finalize. If you saved to Downloads, `blog-it` copies from there into the bundle. If you saved directly to the repo, `blog-it` verifies the file exists.

## Cover Standards

All covers on magnus919.com must conform to these conventions:

| Property | Standard |
|----------|----------|
| **Format** | JPEG, quality 85 |
| **Filename** | `cover.jpg` |
| **Width** | 1600px (locked aspect ratio) |
| **Max upscale** | None. If source is narrower than 1600px, keep native width. |
| **Old files** | Remove `cover.png`/`cover.jpeg` after conversion. Keep `.bak`. |
| **Frontmatter** | `cover: "cover.jpg"` or `image: cover.jpg` (various YAML formats) |

These standards exist because:
- The content area is ~820px wide. 1600px covers 2x Retina perfectly.
- JPEG Q85 is visually lossless for the gonzo style (heavy ink textures with no transparency) at 1/10th the file size of PNG.
- A full set of ~80 covers at 3.5MB PNG = ~280MB. Same set at 1600px JPEG Q85 = ~40MB.

## Batch Cover Conversion Workflow

When Magnus asks to audit or update all blog covers:

1. **Inventory** — List all `content/posts/*/cover.*` files. Check their resolutions.
2. **Classify** — Visually inspect to split into:
   - **Batch A (resize-only):** Already gonzo-compliant. Resize to 1600px and convert to JPEG Q85. Update frontmatter.
   - **Batch B (regenerate):** Non-compliant covers (photorealistic, vector, watercolor, cartoon, etc.). Needs new gonzo image via edits API with reference.
3. **Process Batch A first** — Run `scripts/resize-cover.sh` on each, update frontmatter, verify build.
4. **Process Batch B interactively** — For each cover, restore original from git, feed to edits API with gonzo prompt, SHOW RESULT to user before proceeding, then resize on approval.
5. **Frontmatter sweep** — grep for any remaining `cover.png` references and update them.
6. **Build & verify** — `hugo --minify` should produce no errors. Spot-check on localhost:1313.

See `references/batch-conversion-workflow.md` for the full protocol, known API behaviors, and processing order.

## Inline Diagram Style (Neon Editorial Infographic)

**This is NOT the gonzo cover style.** Inline diagrams for magnus919.com article bodies use a distinct visual identity — see `references/diagram-brand.md` for the locked template.

Key characteristics:
- Rich dark background, semi-transparent colored fills with blended overlaps
- Subtle glow/rim light effects on primary elements
- White sans-serif labels positioned outside elements
- Symmetrical, balanced composition — premium editorial feel
- Established 2026-05-20; replaces the earlier flat technical diagram approach

This style is used for: Venn diagrams, process flows, comparison frameworks, architecture maps, and any explanatory diagram within article bodies. Do NOT use the gonzo cover style for these.

## Subject Ideas (for reference)

Quick-reference list of tested subjects (see `references/tested-subjects.md` for full subject lines and design principles):

- **The Recursing Mind** — Figure in a chair with concentric spirals above their head, room dissolving (tested ✓)
- **The Rebirth Chamber** — Figure in a study where the walls are translucent documents, edges blurring into the writing, amber book glowing at center (tested ✓)
- **The Mesh Node in the Woods** — LoRa board on mossy tree, antenna glowing amber, roots are fiber cables
- **The Threshold Desk** — Desk half-wood half-server-rack, notebook merging handwriting and code, rotary phone cord unspooling into mesh topology
- **The Two Chairs** — Two empty chairs facing each other, storm of ink threads and conversation debris between them

**Reference file:** [`references/tested-subjects.md`](references/tested-subjects.md) — full subject lines, why each worked, and six extracted design principles for replicating the quality consistently.
**Reference file:** [`references/jumping-spider-facial-anatomy.md`](references/jumping-spider-facial-anatomy.md) — eye count, facial features, and cover prompt patterns for anatomically accurate spider illustrations. Consult before writing any jumping spider cover prompt.

Remember: close variants of the same subject work fine — the style carries it, and each article needs its own specific visual.

## Gonzo vs. Flux — Style Reality Check (2026-05-21)

**GPT image generation (gpt-image-2)** is the primary tool for gonzo cover images. It produces genuine mixed-media illustration quality with ink line work, watercolor washes, and controlled delirium.

**Local ComfyUI (Flux.1 Dev FP8)** produces photorealistic images by default. It fights illustration styles — figures come out photorealistic, proportions are clean, and "messy" gets sanitized. It is useful for:
- Unfiltered content (no content safety filters)
- Photorealistic subjects (animals, objects, scenes)
- Quick atmospheric images

For gonzo editorial illustration specifically: use `image_generate` (OpenAI backend), not ComfyUI.

## Pitfalls

- **Cover images only — never use this style for inline diagrams.** The gonzo illustration template produces atmospheric, emotionally resonant images. It is explicitly wrong for technical diagrams, architecture drawings, or explanatory inline illustrations. Inline diagrams use a separate style: the **neon editorial diagram** (see `references/diagram-brand.md`) — dark background, semi-transparent colored fills with glow effects, white labels outside elements, polished editorial feel. This was established 2026-05-20 and replaces the earlier flat technical diagram approach.
- **The gonzo template is the ONLY style for cover images — never use the diagram style for a cover.** The neon editorial diagram style is for inline explanatory graphics. It produces images that look like premium magazine infographics: colorful, vibrant, information-focused. That is the wrong mood for a magnus919.com cover image. Every cover must use the gonzo template from this skill. If a diagram-style image seems appropriate for the subject matter, generate a cover anyway and let the article body carry the diagrams. The cover's job is atmosphere and emotional hook, not information delivery. Corrected 2026-05-12 and again 2026-05-20.
- **Be anatomically precise with living subjects.** When the cover image subject is an animal with specific structural features, verify those features before writing the SUBJECT line. For jumping spiders specifically: each side of the face shows TWO visible eyes — the large principal eye (anterior median) and a smaller secondary eye (anterior lateral) beside it. A prompt describing only one eye per side produces an anatomically wrong image. Research correct eye count, limb arrangement, and proportions for any creature before writing the prompt. The reference file `references/jumping-spider-facial-anatomy.md` has the full anatomy breakdown for jumping spiders. Corrected 2026-05-24: original and Article 2 covers both had wrong eye counts.

- **gpt-image-2 cannot render precise object shapes.** The model defaults to abstract/symbolic interpretations of specific geometric descriptions. Describing a key as "shaped like a markdown file with a document-file-icon handle" produces an auction-paddle-like shape, not a recognizable key or file icon. This is a model limitation — gpt-image-2 excels at mood, composition, and texture but not at following precise structural specifications. Workaround: use broader metaphors (let the object be a simpler version of itself) or use the edits API to surgically fix distorted elements in a first-generation image that otherwise has the right composition. Do not iterate more than 1-2 times trying to get a precise shape from gpt-image-2 — it won't converge.

- **When a text-to-image generation is 90% right but one element is wrong, prefer the edits API over regenerating from scratch.** The edits API preserves composition, colors, and overall scene while allowing targeted fixes. This session's worked example: a gonzo walled-fortress image had the right wall (GitHub cat blocks, red X marks) but the figure held an auction-paddle-shaped object instead of having hands at their sides. The edits API fixed it in one shot. See `references/edits-api-iterative-refinement.md` for the full recipe.

- **When a reference image exists, use the edits API — NOT `image_generate`.** The user explicitly corrected this (May 2026): "image_generate is the WRONG tool. You need to be uploading to the image_edit endpoint with reference images." Path B (edits API) is the correct approach when a reference image is available. Path A (text-to-image) is only for pure conceptual generation with no reference.

- **Edits API can output landscape natively.** Use `size=1792x1024` rather than square. This was tested and confirmed working (May 2026). The 1792x1024 result can be downscaled to 1600x914 JPEG Q85 for the repo — no upscaling required. The previous square-only assumption was incorrect.

- **The edits API can take 30-120+ seconds.** Always use `--max-time 300` with curl or `timeout=300` with Python requests. The 120s default is insufficient — the API regularly exceeds it.

- **Do NOT use `source ~/.hermes/.env` in `set -e` scripts.** The .env file has malformed lines that cause exit code 127. Extract the OPENAI_API_KEY via grep instead: `grep '^OPENAI_API_KEY=*** $HOME/.hermes/.env | sed 's/^OPENAI_API_KEY=***`. See the Path B section above for the exact Python extraction pattern.

- **Show edits API results interactively before batch-processing.** When converting multiple covers with the edits API, show each result to the user for approval before proceeding to the next. Do not batch-generate and apply all at once.

- **Do not crop edits API square output and upscale.** If you accidentally request square (1024x1024) instead of landscape (1792x1024), do NOT crop to 16:9 and resize up to 1600px. The user corrected this as making the image look "crap." Either re-request with the correct landscape size, or accept the square aspect ratio. The correct fix is always to use `size=1792x1024` in the first place.

- **Frontmatter has three YAML formats, not one.** Posts use `cover: "cover.png"`, `cover: cover.png`, or block format `cover:\n  image: cover.png`. The `update_frontmatter()` function in scripts/gonzo-convert.py handles all three. A single sed pattern will miss most. After any batch update, run a grep for remaining `cover.png` references.

- **Rescan for unprocessed posts after a batch operation.** Posts with non-standard cover filenames (e.g. `image.png` instead of `cover.png`), posts without explicit cover frontmatter (AutoCover), and posts you simply didn't include in the batch list will be missed. After any batch cover conversion, scan for posts that still have `cover.png` on disk but no `cover.jpg`.

- **Scan for posts in subdirectories.** Posts are not always in flat directories under `content/posts/`. They can live in subdirectories like `content/posts/ari/mirror`, `content/posts/ari/between-tokens-and-truths`, or `content/posts/news/2025-06/ai-news`. A scan that only looks at the top level of `content/posts/` will miss these. Use `find content/posts -name 'index.md'` to get a complete list of all post directories, then check each for cover files.
- 
- **Nonstandard cover filenames are common.** Not all posts use `cover.png` as their cover filename. Common alternatives found in the wild: `image.png`, `furby.png`, `podman.webp`, `macbookairm1.png`, `cover.webp`. These are legitimate covers that are invisible to `ls content/posts/*/cover.*`. When scanning for unprocessed covers, check for ANY image file (`.png`, `.jpg`, `.jpeg`, `.webp`) in the post directory, not just files named `cover.*`. Also check frontmatter for `cover:` or `image:` fields pointing to nonstandard filenames.

- **Flat markdown files use absolute or relative cover paths, not page bundles.** Not all posts are `content/posts/<slug>/index.md` page bundles. Some are flat `.md` files inside category directories (e.g., `content/posts/NY-AI-Meetup/2025-06-06.md`, `content/posts/AgileRTP/2025-05-06.md`). These often use `cover: "/images/something.png"` (absolute path to `static/images/`) or `cover: "images/cover.png"` (relative path within the post's directory tree). When scanning for covers, search for ALL cover references — not just `cover.*` files in page bundles. Use: `find content/posts -name "*.md" -exec grep -l "^cover:" {} \\;` to find all posts with explicit cover references, then check each one's format.

- **Shared static images need individual per-image conversion.** When multiple flat `.md` files reference the same absolute path (e.g., multiple NY-AI Meetup posts all use `/images/NY-AI.png`), convert the source static image once, save the gonzo version as a new file (e.g., `NY-AI_gonzo.jpg`), then update all referencing frontmatter entries. Do NOT attempt to create per-post bundle covers — the flat file structure doesn't support it.
- 
- **The edits API may reject certain subjects via safety system.** Names like "Oracle" (DC Comics character), "Jony Ive", or other public figures can trigger OpenAI's content safety system, returning: "Your request was rejected by the safety system." Workaround: rephrase the prompt to describe the scene without naming the subject directly (e.g., "a figure in a wheelchair before glowing screens" instead of "Barbara Gordon as Oracle"; "sleek minimalist design forms" instead of "Jony Ive"). Build the prompt around what the image LOOKS like, not who or what it is OF. See `references/edits-api-quirks.md` for the full pattern and workaround details.
- 
- **Edits API via Python requests: write PNG to disk, don't use BytesIO.** When using Python's requests.post with files={'image': ('image.png', buf, 'image/png')}, passing a BytesIO buffer can fail with "Invalid image file or mode" errors — particularly with images converted from WebP or RGBA PNGs. The reliable fix: write the 1024x1024 square PNG to a temp file on disk (image.save('/tmp/prepped.png', format='PNG')), then read it back and pass the raw bytes (open('/tmp/prepped.png', 'rb').read()). This consistently works where BytesIO fails.

## Gonzo Style with Local Flux/ComfyUI

The `image_generate` tool uses the configured API backend for generation. If that backend is Flux via local ComfyUI (gpuslut01), be aware of a fundamental mismatch:

**Flux is a photorealistic diffusion model.** Even with strong style prompting and illustration-style LoRAs, it defaults to "beautiful" — smooth gradients, coherent lighting, clean edges. The gonzo style requires deliberate imperfection: frantic dip-pen linework that overshoots corners, violent crosshatching, ink splatter, anatomy that's wrong on purpose. Flux fights this.

**Tested results (May 2026, RTX 5070 Ti, Flux.1 Dev FP8):**

| Approach | Style fidelity | Issue |
|----------|---------------|-------|
| Flux raw prompt | ~75% | Figure too photorealistic, background too clean |
| Flux + "simple illustration" LoRA | ~80% (medium) | Now looks like ink on paper, but too tidy — "simple" means neat |

The LoRA improves the *medium* (makes it look like ink on paper) but degrades the *spirit* (cleans up the chaos that gives gonzo its energy). A LoRA trained specifically on frantic/scratchy illustration might help, but this is fundamentally pushing Flux against its training distribution.

**Practical guidance:**
- For atmospheric, surreal, photorealistic images — Flux is excellent
- For the gonzo illustration style — prefer the API-based `image_generate` tool if it uses a non-Flux backend (DALL-E, Midjourney, etc.) that handles illustration better
- If you must use local Flux for a cover, accept a 70-80% style match and lean into the "controlled" side of "controlled delirium" — Flux is better at eerie precision than violent ugliness
