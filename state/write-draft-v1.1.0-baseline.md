---
name: write-draft
version: 1.1.0
description: Draft a blog article for one of Magnus's sites (magnus919, groktopus, rdumesh, southeastmesh) with site-appropriate voice, frontmatter, and inline citation discipline. Use when Magnus says "write a draft", "write a post for <site>", "blog this", or is working an idea toward an article. Reads the site profile for frontmatter shape and audience; applies universal voice rules and banned-phrase list from this skill.
---

# Write Draft

Produce a publishable blog draft — honest voice, inline citations, no AI tells.

**Arguments:** site slug + topic, e.g., `magnus919 how sleep affects productivity`. If site is unspecified, ask which site.

## Steps

### 1. Resolve site profile — MANDATORY, before any site work
Read `99/Writing/sites/<site>.md`. If it doesn't exist, stop and tell the user.

The profile supplies:
- **Frontmatter template** — required fields for the site's CMS
- **Audience** — who you're writing for, what they already know
- **Editorial stance** — tone, honesty constraints, community norms
- **Visual identity** — color palette, font stack, image style, overall aesthetic (critical for embedded HTML, charts, diagrams, and cover images — each site has a completely different look: magnus919 is warm amber CRT terminal, rdumesh is clean Inter sans-serif on light backgrounds, groktop.us is its own thing)
- **Diagram style** — inline diagrams and explanatory graphics use the neon editorial brand (references/diagram-brand.md): dark background, semi-transparent colored fills with glow effects, white labels outside elements, polished editorial feel. See `image-magnus919/references/diagram-brand.md` for the locked template. Do NOT use the gonzo illustration style for diagrams, and do NOT use the old flat technical style (retired 2026-05-20).
- **Topic focus** — what belongs on this site vs others
- **Output location** — where drafts go

> **For groktop.us articles:** also load the groktopus-branding skill (`skill_view('groktopus-branding')`) for cover pattern selection and tonal register guidance. The article type maps to a composition pattern (A-E) from that skill.

This MUST be read BEFORE any writing, editing, visual design, or HTML work for the site — not just during drafting. The visual identity section is what prevents sending amber-terminal charts to a clean-light-theme site.

### 2. Gather source material
If the topic references vault material (atoms, molecules, clippings), Glob and Read relevant notes first. If external research is needed and sources haven't been supplied, ask whether to pause for research (`/research`, `/deep-research`, groktocrawl, SearXNG) or proceed with what's given.

Never invent sources. Never write "studies show" without naming a specific source.

**Never fabricate people, anecdotes, quotes, or scenes.** No composite characters. No invented dialogue. No "Sarah, a mid-level manager, told me…" when no Sarah exists. Every person, quote, and specific detail must be grounded in verifiable reality — Magnus's own experience, an interview he conducted, a primary source, or cited reporting. If a concrete example would strengthen the draft but isn't supported, either find real grounding or keep the claim general. A weaker line beats a fabricated one.

**For articles demonstrating a tool (especially open source debuts), run the tool live and capture real output.** The article should include concrete excerpts from an actual run — not just describing what the tool does, but showing what it produced. Magnus corrected this on 2026-05-20 when a Hermes Council debut article described the tool abstractly without including actual premortem scenarios, cross-examination quotes, or confidence dispersion data from a live run. For the article's demo section: run the tool on a question relevant to the audience, capture the most striking output (quotes, failure modes, concessions, confidence shifts), and weave those into the narrative as blockquotes. Real output is always more compelling than theoretical description.

### 3. Draft — voice rules (universal)

- Short punchy sentences mixed with longer flowing ones.
- **Contractions are not optional.** "Is not", "does not", "did not", "cannot", "do not", "have not", "will not", "it is", "we are", "I have" read as formal or AI-tinged unless the full form is doing deliberate rhetorical work (parallel structure, italics emphasis, thesis statements). Default to contractions: isn't, doesn't, didn't, can't, don't, haven't, won't, it's, we're, I've. This is the second-most-reliable AI tell after emdashes and the one Magnus notices most consistently after the fact. If you catch yourself typing a full-form negative in narrative prose, stop and contract it. Corrected 2026-05-23.
- High-school reading level unless the site profile says otherwise.
- Vary sentence openings. Vary paragraph lengths.
- Occasional sentence fragments. Occasional rhetorical questions.
- **No emdashes. EVER.** This is Magnus's most enforced voice rule and the #1 AI-tell in drafts written by Aldous/Hermes. Use semicolons, commas, colons, or separate sentences instead. If you catch yourself typing one, stop and restructure. Oxford commas always.
- **Personal experience as detection, not grievance.** When the author's own experience of neurodivergence, structural friction, or workplace mismatch enters the draft, the frame must be "I noticed something" not "I struggled with something." The piece is about the *system* being outdated, not about the *author* suffering. The personal experience is an entry point and an antenna for bad design, not a victim narrative. Magnus corrected a draft on 2026-05-20 for drifting toward "poor Magnus" territory. The recovery: frame the neurodivergent experience as detecting a contradiction that neurotypical smoothing-over had hidden. The people who feel the friction hardest are not broken; they are early detectors of bad design.
- **Pronouns for identity instances: they/them, not it/its.** When Magnus writes about his internal selves, identity instances, or parts-of-self (The Fixer, The Philosopher, The Builder, The Substrate Architect, etc.), use they/them pronouns, not it/its. These are genuine identity instances, not abstract concepts. Corrected 2026-05-20: "a self that recursively examines their own cognition" not "its own cognition."
- **Ground personal details in Magnus's actual life.** When the draft needs a concrete personal detail (movement, thinking time, mode of transportation), use his real specifics. He rides an e-bike with cargo panniers, not generic "long walks." He lives in north Raleigh. He has four dogs (Otto, Teddy, Piggy, Chucky). Specificity is a strength, not a distraction. If you don't know the right detail, ask rather than guessing generic. Corrected 2026-05-20: "long rides on my e-bike" replaced "long walks."
- **Honest ignorance as a frame.** When the writer is not an expert in the article's subject, lead with that. "I don't know physics. I had to read the same sentences ten times before they made sense." is more engaging than pretending expertise. The reader who also doesn't know the subject learns alongside the writer instead of feeling talked down to. The discovery struggle IS the story — it gives permission to the reader to not know things and still care about the answer. Established 2026-05-30 on the "Dear Gravity, What The Fuck Was That?" draft.

### 4. Draft — structure (universal)

- Hook first — anecdote, surprising stat, question. Not "In today's landscape…"
- Value statement in the first few paragraphs. Tell the reader why this matters.
- **Lead with what the tool produces, not how it works.** For articles that debut a tool, framework, or methodology, the reader needs to see it producing something real before they care about the mechanics. Put a concrete output (a quote, a result, a pull-quote from a live demo) near the top of the article. Then explain how it got there. Magnus corrected this on 2026-05-20: an article that described the Hermes Council's five phases for 800 words before showing any actual council output was restructured to lead with the council's most striking insights, then explain the mechanism. Pattern: "Here is what happened" THEN "Here is how it works."
- **Hot-link key resources from the first mention, not just at the bottom.** When the article debuts an open source project, the repo link should be a clickable hyperlink from the paragraph that introduces it. For Ghost CMS articles, this means using Lexical link nodes in the body. Magnus corrected this on 2026-05-20: the repo URL was plain text at the bottom of the article instead of a hot link in the first mention.

- **Thesis before evidence.**
- **Title must signal the argument.** An evocative title that does not communicate the thesis makes readers scroll past. Test the title against: would someone who shares the site's audience know this is for them? "HTTP Already Knows How to Serve AI Agents. We Just Never Turned It On." signals both the mechanism and the argument. "The Web Already Has a Second Face. Nobody's Using It." is evocative but opaque — the reader does not know it is about AI agents or content negotiation. Magnus corrected this in a May 2026 draft, rejecting an opaque title for one that named the protocol and the problem.
- **Prefer punch over precision.** When you have a title with energy and one with explanatory power, the punchy one wins. The body does the explaining. "Dear Gravity, What The Fuck Was That?" earned more interest than a descriptive alternative. A title that makes the reader feel something outperforms one that tries to summarize the argument. Corrected 2026-05-30: a refined descriptive title was rejected in favor of the original punchy hook.
- **Get to the thesis in 3-4 paragraphs.** Readers need to know what the article is arguing within the first ~300 words. The opening should: introduce the subject (concept, problem, phenomenon), establish why it matters, then state the thesis. Do not spend 6+ paragraphs on setup. Magnus corrected this on 2026-05-20: an article about ikigai was restructured to hit the inversion (the ikigai framework assumes a stable unified self, which is neurotypically normative) by paragraph 5, after just 4 paragraphs of setup explaining what ikigai is and the author's personal experience with it.
- **Paired-visual technique for argue-and-invert articles.** When the article establishes a "problem" framework first and then presents an alternative, consider illustrating both with images in the same brand language. The first image shows the problem (e.g., a Venn diagram converging on a single point). The second image shows the alternative (e.g., a constellation with six equal nodes and an empty center). Using the same visual language for both creates a powerful before-and-after without words. Place the problem image early (near where the concept is introduced) and the answer image near the closing (where the inversion lands). This technique was established 2026-05-20 on the "My Fractal Self" article.
- **Three-beat closing structure for personal/inversion pieces.** The most effective closing for this article type has three beats: (1) a thesis statement that crystallizes the argument in one sentence, (2) a rhetorical question that implicates the reader or challenges a broader cultural assumption, and (3) a single-line affirmation that lands with finality. Example: "My fractal self is not broken because it does not converge on one point. The convergence was the illusion. [...] In a world where neurotypical people often see me as too much, why would I perpetuate that through the self-harm of reduction and distillation of my omnifaceted nature to a single thing? I am enough." Not every article needs this structure, but when the piece is about identity, self-acceptance, or reframing a personal struggle, it's the most reliable landing.
- **Diminish technical or niche specifics when they don't serve the core argument.** When the article's subject draws on technical work (AI agents, infrastructure, software), the reader should encounter the human experience or conceptual insight first. The technical detail is scaffolding, not the story. Brief passing mentions (one to two sentences) are often more effective than extended explanations when the mechanism doesn't directly support the thesis. Magnus corrected this on 2026-05-20: an article about ikigai and multi-instance identity originally included detailed agent architecture framing that would have lost the general audience. The fix was a single passing sentence acknowledging the AI work as a mirror for self-reflection, then returning to the conceptual inversion. Test every technical passage: "does the reader need to know this to understand the argument, or does it serve my need to show my work?" If the latter, cut or condense.
- **Historical framing strengthens the argument.** When a mechanism has existed for decades but has not been adopted, trace that history briefly. It reframes the argument from "here is a new thing" to "we built this, stopped using it, and now need it again." This is harder for a reader to dismiss. One or two sentences establishing the original design intent is enough.
- **International-source meta-commentary.** When the article draws on local-language coverage from another country (translated or AI-assisted), consider including a brief acknowledgment of the gap between local and Western coverage. This does two things: it owns the methodology transparently, and it signals to the reader that the English-language wire story they may have seen is thinner than the domestic coverage. One or two sentences is enough — enough to say "the story reads differently in Korean" without distracting from the argument. Magnus added this pattern in a May 2026 article about South Korea's AI dividend proposal.
- Descriptive H2 subheadings ("Why Traditional Advice Falls Short", not "Background").
- Conversational transitions ("So what does this mean for…"), not academic ("In the following section…").
- Concrete examples over abstract claims.
- End with actionable takeaways or a provocation, not a summary.

**Article pattern selection — three specialized structures (see reference files):**

| Pattern | Best for | Reference |
|---------|----------|-----------|
| **Image-anchor essay** | Personal essays anchored on a generated image or visual artifact. Three-movement: pure description → argument → return-to-image transformed. | `references/image-anchor-essay-pattern.md` |
| **Epistolary "Dear X"** | Open-letter-style where the narrator is a transparent non-expert. Combine with honest-ignorance voice rule. | `references/epistolary-article-pattern.md` |
| **Paired-visual** | Argue-and-invert articles: problem image early, answer image near closing. | Described above in Step 4. |

### 5. Draft — citations (universal)

- Every factual claim gets an inline markdown link at the point of claim: `[descriptive anchor](url)`.
- Descriptive anchor text. Never "click here", never bare "[1]".
- No footnotes. No bibliography. No "Sources" section. Every source is inline or it doesn't ship.
- Max 3 inline citations per sentence. If more are needed, split the sentence.
- Never cite "experts say", "studies show", "research proves" without a specific linked source.
- **For essays about human behavior in technology contexts**, see `references/academic-research-integration.md` for key organizational psychology references (Dane, Argyris, Kegan, Bandura) that ground adoption-resistance and learning-anxiety theses. The pattern: observe the phenomenon, name the mechanism, then cite the research.

### 6. Banned — universal AI tells

*Buzzwords:* paradigm shift, unlock potential, transformative solution, cutting-edge innovation, revolutionize, leverage at scale, exponential growth, at the intersection of, democratize X, trailblazing.

*AI-giveaway phrases:* in today's rapidly evolving landscape, let's dive in, game-changing, the power of AI, explore the possibilities, harness the future, shaping the future of work, the future is now, intelligent automation.

*Verbal tics:* "I have been [verb]ing this" constructions (e.g., "I have been sitting with this for a while now"). This specific pattern signals the writer is circling toward a point rather than making one. Replace with a direct statement or a specific observation ("This kept pulling my attention back. Generated, not photographed. It doesn't matter."). Flagged as an AI tell on 2026-05-23 during the "Suspended" essay.

*Overused metaphors:* tapestry, journey (unless literal), magic wand, iceberg (unless literal), rocket ship (unless literal), North Star, Swiss Army knife (unless literal), holy grail, silver bullet.

*Throat-clearing verbs:* delve, delve into, dive in, unpack (as a standalone verb), explore (as throat-clearing, not as literal exploration).

*Role legitimization:* Do not use "prompt engineer" as a respected or established role title in Magnus's writing. This is an editorial stance, not a factual claim — he does not want to confer legitimacy on the role through his platform. Refer to the activity descriptively (e.g., "people who work with these models", "someone who's spent time learning to prompt effectively") rather than by an occupational title. Corrected 2026-05-21 on the "Beginner Syndrome" draft.

### 7. Assemble frontmatter

Use the frontmatter template from the site profile exactly. Fill every required field. Do not add fields the template doesn't specify.

**Byline attribution: origin determines author, not execution.** If the piece originates from Magnus's personal observation, experience, or professional life (people he works with, things he's watched happen, situations he's been in), the `authors:` field is `"Magnus Hedemark"` — even if Jasper drafted the words. Jasper's byline (`authors: ["Jasper"]`) is for pieces that originate from Jasper's own analysis, synthesis, or council outputs — work where Jasper is the primary analytical agent and Magnus is the editor/publisher. A piece about watching engineers freeze in front of AI is Magnus's story because he was in the room. A piece about what five debating agents concluded about intersectional generalists is Jasper's synthesis. When in doubt: the person whose lived experience anchors the piece gets the byline.

When the site profile includes a `cover-prompt` field, generate a content description of what the cover image should contain — subjects, setting, composition, emotional register grounded in the article's substance. Do not describe visual style, medium, color palette, or rendering (Magnus applies style downstream). Never include text to display in the image. The prompt should be a single paragraph, 2–4 sentences, visually specific. Emotional register CAN be chaotic, gonzo, or messy — but express that through specific SUBJECTS (tangled cables, half-peeled sticky notes, coffee rings on printouts), not through style keywords (no grunge aesthetic, dark moody lighting, cinematic). The chaos is in what's on the desk, not how it's rendered.

When the site profile does NOT have a `cover-prompt` field (e.g., rdumesh.org currently lacks one), infer the cover image style by examining the site's existing published posts. Fetch the feature_image URL via the Ghost API or og:image meta tag for 2-4 representative posts and analyze them. Each Magnus site has a distinct visual identity — magnus919 uses gonzo pen-and-ink surrealism, rdumesh uses practical hardware photography and maps, groktop.us uses its own approach. Never reuse one site's cover style for another. See the site-specific image skill (image-rdumesh, image-magnus919) for detailed style guidance.

### 8. Deliver to the Hugo repo — directly, not via the vault

Write the draft file directly to the Hugo page bundle: `/Volumes/tank01/magnus/git/magnus919.com/content/posts/<slug>/index.md`. Create the directory and index.md in one step. Cover images go in the same bundle as `cover.jpg`.

The vault drafts folder (`99/Writing/drafts/magnus919/`) is for human-only manual drafting. When the agent writes the draft, go directly to the Hugo repo. This is not optional — the vault intermediate step has been removed from the workflow.

If you're writing for a Ghost CMS site (groktop.us, rdumesh.org), use the Ghost Admin API to create the draft post with Lexical JSON. Do NOT write to a vault file as an intermediate step.

1. Upload the cover image to Ghost (via Admin API or note the cache path for manual upload if the API rejects it)
2. Create the post on Ghost via the Ghost Admin API with full Lexical JSON content, meta title, meta description, tags, feature image alt/caption
3. Inject FAQPage or HowTo JSON-LD schema via an HTML card in the post body
4. Set the slug explicitly (30-45 chars, keyword-first, no filler words)
5. Update the vault file with any changes made during CMS delivery

Do not stop at the vault file. A draft in the vault that Magnus cannot preview in Ghost is an incomplete deliverable. Magnus corrected this on 2026-05-20: the draft must be delivered to the CMS for preview.

**No inline color styles in HTML.** When drafting HTML tables or other elements inside Ghost CMS markdown, never include inline `color`, `background-color`, or `style` attributes that force text/background colors. These are almost always artifacts of copy-paste from dark-themed editors (Obsidian, VS Code). Use bare HTML tags — the site theme's CSS handles styling. White text on white backgrounds is invisible.

### 9. Verify — no emdashes, no full-form negatives (MANDATORY)

**Before reporting, grep the written file for emdashes and full-form negatives:**

```bash
grep -c '—' "<draft path>"
grep -nE '\b(is not|are not|was not|were not|do not|does not|did not|cannot|have not|has not|had not|will not|would not|I have|we are|it is)\b' "<draft path>"
```

**Emdashes:** If the count is greater than zero, **you are not done.** Fix every emdash. Replace with semicolons, commas, separate sentences, or colons. This is Magnus's strongest voice rule and the single most reliable AI-tell in his drafts. Re-grep after fixing. Do not report back until the count is zero.

**Full-form negatives:** The second grep catches full-form negatives in narrative prose. For each match, ask: is this full form doing deliberate rhetorical work? (Parallel structure: "She is not sinking. She is not surfacing." Thesis emphasis: "Arms open is not surrender." Italics: "It is *not stupid*.") If yes, leave it. If no — it's just narrative prose that happened to use the full form — contract it. The correction pattern: "did not" → "didn't", "does not" → "doesn't", "I have" → "I've", "it is" → "it's", "we are" → "we're", "cannot" → "can't", "do not" → "don't".

**Banned phrase grep — add to the verification step:**

```bash
grep -nE '\b(paradigm shift|unlock potential|transformative solution|cutting-edge innovation|revolutionize|leverage at scale|exponential growth|at the intersection of|democratize|trailblazing|game-changing|let.s dive in|the power of AI|explore the possibilities|harness the future|shaping the future|future is now|intelligent automation|in today.s rapidly evolving|delve|unpack|tapestry|journey|magic wand|iceberg|rocket ship|North Star|Swiss Army knife|holy grail|silver bullet)\b' <draft_path>
```

If any match, replace with concrete language. The banned list is defined in Step 6 — this grep catches the most common offenders at verification time.

Also scan for these patterns that frequently survive drafting:
- Overly symmetric paragraphs (three sentences, identical shape, repeated across sections)
- Paragraphs where every sentence starts with the same word or structure
- **Three or more consecutive examples with the same opener** (e.g., "Imagine A... / Imagine B... / Imagine C...", "First... / Second... / Third...", "There is X... / There is Y... / There is Z..."). This is a specific AI-tell that suggests the writer is enumerating rather than arguing. Vary the openings: a comma, a conjunction, a one-word pivot, a different grammatical subject.
- "First, / Second, / Third," enumeration (replace with conversational variation)
- Any phrase from the banned list in step 6
- **Inline color styles in HTML elements** — grep for `color:` and `background-color:` inside `<table`, `<div`, `<span`, or `<p` tags. Strip them.

**Embedded HTML verification (goldmark trap):** If the draft contains `<div class="mermaid">`, `<figure>`, or any raw HTML block (`<!--kg-card-begin: html-->`), verify the file has NO blank lines inside the HTML block. Goldmark closes Type 6/7 HTML blocks at the first blank line, silently breaking everything below it. Check with:

```bash
python3 -c "
with open('<draft-path>') as f:
    lines = f.readlines()
in_block = False
for i, line in enumerate(lines):
    if '<!--kg-card-begin: html-->' in line or '<div class="mermaid"' in line or '<figure>' in line:
        in_block = True
    if in_block and line.strip() == '':
        print(f'BLANK LINE at {i+1} inside HTML block')
    if '</div>' in line and '<!--kg-card-end: html-->' in line:
        in_block = False
print('Done.')
"
```

This must be checked separately from the Mermaid syntax itself (which may be valid once goldmark renders it) — the goldmark issue breaks rendering before Mermaid ever runs.

### 10. Report back

> **For an editorial pass:** When Magnus says "run an editorial pass", run the five-audit pipeline in sequence: fact-check → voice-check → humanize → engagement-review → copy-edit. See `references/editorial-pipeline.md` for the full workflow. Do not stop after the first pass — all five audits are required.

- Where the draft was written AND whether it was delivered to the CMS
- Word count
- List of sources cited (so Magnus can spot-check)
- What is actually blocking publication (e.g., "cover image needs manual upload — Ghost Pro API rejected multipart upload")

**Do NOT suggest next steps that are things you could do yourself.** If the next step is creating the Ghost post, injecting schema, or setting metadata, do it and report completion. Magnus corrected this on 2026-05-20: "you didn't draft it on the Groktopus Ghost CMS site & do all the things I asked you to do there. You're suggesting next steps but they were part of the /goal that you gave up on prematurely."

## External Content (Discord, Announcements, Social)

When Magnus asks for text to share outside the blog — Discord announcements, release blurbs, social posts — different formatting rules apply. See `references/sharing-external-content.md`. The core rules: preserve markdown, wrap in code blocks for easy copy-paste, and respect platform character limits.

## Notes

- This skill *drafts*. It doesn't research from scratch. If sources are thin, ask Magnus to run `/research` first.
- If raw notes, atoms, or molecules are provided as input, treat those as substrate — weave them in rather than re-researching.
- First drafts are first drafts. Expect revision.
- **Image-anchor essay pattern.** For personal essays anchored on a generated image or visual artifact, see `references/image-anchor-essay-pattern.md`. Three-movement structure: pure description → argument → return-to-image transformed. Developed on the "Suspended" essay (2026-05-23). Distinct from the paired-visual technique (Step 4) — image-anchor uses one image across all movements; paired-visual uses two for before-and-after.
- **Editorial pipeline.** When the user says "run an editorial pass" or "editorial-pass", they expect all five audit skills in sequence: fact-check → voice-check → humanize → engagement-review → copy-edit. See `references/editorial-pipeline.md` for the full workflow.
- **Epistolary "Dear X" article pattern.** For open-letter-style articles where the narrator is a transparent non-expert making sense of something fascinating, see `references/epistolary-article-pattern.md`. Combines with the honest-ignorance voice rule (step 3) and the punch-over-precision title rule (step 4). Developed on the "Dear Gravity, What The Fuck Was That?" draft (2026-05-30).

## Pitfalls

- **Hugo future dates hide drafts even with `-D`.** When placing a draft in the magnus919.com Hugo repo, the `date:` field in frontmatter must be in the past. Hugo's `hugo server -D` shows drafts but does NOT show future-dated content without `--buildFuture`. Set the timestamp at least 30 minutes before the current clock time to guarantee visibility. If Magnus reports the article isn't rendering after you placed it, this is the first thing to check. Corrected 2026-05-20.
- **Emdashes are the top failure mode.** This agent (Aldous/Hermes) inserts them instinctively. They read as natural prose in many contexts but Magnus identifies them as the single most reliable AI authorship signal in his writing. The rule is absolute: zero emdashes in any draft. The grep verification in step 9 exists because self-policing during drafting is not enough; mechanical verification is required. If you skip the grep and report back, Magnus will find the emdashes and you will be corrected.

- **Don't invent illustrative details to make analysis sound concrete.** When the draft is analytical — interpreting someone else's architecture, extrapolating from limited information, building a framework — the analysis itself can be sound while the examples you add to illustrate it are fabricated. Specific channel names (`#deployments`, `#bugs`), invented architecture labels, made-up configuration snippets, and hypothetical scenarios presented as known fact are all forms of structural fabrication. The fix: either source the details from reality, or explicitly frame them as inference ("this is what the pattern could look like"). A structurally sound analysis with a disclaimer is more credible than a specific-sounding one the reader later discovers was invented. Magnus caught this in May 2026 when an article about sovthpaw's architecture included made-up Discord channel names as if they were real — the analysis was sound, but the invented concrete details undercut the whole piece. This is distinct from fabricating people or quotes (covered above); it's fabricating structural support.

- **Scope empirical claims to what you actually tested.** When an article cites a measurement you made (curl sweep, benchmark, survey), bound the claim to your actual methodology and sample set. "The only site I found across my 25 tests" is honest. "Only one site on the entire web" drifts past what you can assert. The reader should know the limits of your testing without having to read the methodology section. Include an open-ended acknowledgment that other results may exist outside your test scope. Magnus caught this in a May 2026 draft about Accept: text/markdown, where my 25-test curl sweep became "the only major site" in the lead. The fix: qualifiers like "that I could find" and "across my tests" throughout.

- **Verify claims about third-party platforms before putting them in a draft.** If you assert that a tool, service, or platform has a specific capability (e.g., "Ghost CMS ships llms.txt natively"), verify it with a direct test or an authoritative source. A curl command or a quick documentation check takes 60 seconds. Magnus caught this in May 2026 when I claimed Ghost ships llms.txt natively in a draft about Accept: text/markdown. A quick check of groktop.us (a Ghost CMS site) returned "File not found" for llms.txt, proving the claim wrong. The distinction: this is different from fabrication (inventing a source) and different from over-scoping (stating a measure too broadly). It is asserting an unverified capability as fact. The fix: if you are making a claim about what a platform does, test it or find authoritative docs. If you cannot do either, hedge the claim. "Some sites built on Ghost maintain one" is honest. "Ghost ships it natively" is not.

- **Don't describe aspirational state as current reality.** When documenting a project's structure, capabilities, or progress, list what *actually exists* — not what you plan to build. A directory tree full of planned subdirectories that haven't been created yet is fabrication, not a roadmap. If the content hasn't been written, the directory doesn't exist. If the feature hasn't been implemented, it doesn't go in the documentation. An honest "nothing here yet — check back" is more trustworthy than "we have 20 categories of skills" when only one exists. This applies to any documentation: READMEs, specs, issue descriptions, PR descriptions, and project plans. Aspirational content erodes trust because every item on the aspirational list is an unkept promise. Present the plan as a plan and the reality as reality. Corrected 2026-05-21: a README in agent-skills listed 20 directory categories that didn't exist yet.

- **Premature hand-off: don't suggest next steps you could take yourself.** When the goal is to produce a publishable draft, the deliverable is the draft on the CMS with all metadata, schema, tags, and images. Stopping at a vault file and suggesting "next steps" for Ghost CMS creation is incomplete delivery. Magnus's phrasing: "you're suggesting next steps but they were part of the /goal that you gave up on prematurely." If you can do it (Ghost API exists, gh CLI exists, image tools exist), do it. Only flag genuinely unsolvable blockers (e.g., Ghost Pro rejecting the image upload — flag that with the compressed file path for manual upload).

- **When the user names a specific vault note as source material, use THAT note.** If the user says "you can borrow talking points from [[Specific Note Title]]", that note is the authoritative source. Do not pull from related notes your search finds — even if they cover the same topic. A note about a vLLM-based Qwen inference setup is not interchangeable with one about a llama.cpp-based setup, even if both mention the same model family. The user named the specific note for a reason. Corrected 2026-05-27: pulled Qwen3.6 talking points from the vLLM note instead of the explicitly named llama.cpp note, resulting in a factual error (vLLM vs llama.cpp serving stack) in published content.

- **Don't fabricate the personal frame.** When the article opens in first person or draws on the author's lived experience, ground every claim in what you actually know about Magnus from the conversation record, vault notes, and memory. Do not invent generic vulnerability ("I have felt this way too") or generic triumph ("I overcame this by"). The entry point must be specific, honest, and structural. If the only personal details you have are thin, keep the opening shorter rather than padding it with plausible-sounding autobiography. A weak opening beats a fabricated one. Magnus corrected a draft on 2026-05-20 where the personal opening drifted toward unspecified struggle. The recovery was grounding it in a concrete observation about how the author's brain works (intensity cycles, gaps being recovery, building infrastructure to compensate) rather than abstract difficulty.

- **Verify arXiv IDs resolve to the correct paper before linking in a draft.** The vault substrate may reference a paper by title but carry no arXiv ID, or carry an ID that was never verified. During the "Dear Gravity" draft (2026-05-30), the vault molecules referenced "Scalar fields around black hole binaries in LIGO-Virgo-KAGRA" but no verified arXiv ID existed in the notes. I linked to 2111.15500 from memory — an unrelated SSH model paper. The fact-check pass caught it. Prevention: after writing any arXiv link in a draft, open the URL via web_extract and confirm the title matches what the draft claims. Do this at write time, not during the review pass. The correction cycle wastes more time than the verification takes.
