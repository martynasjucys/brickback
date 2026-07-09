# Phase 8 — Marketing Site (Next.js 16)

**Goal:** the public-facing marketing site that sells BrickBack and drives app installs.
Independent of the mobile app — **can be built in parallel at any time** since it only
reads the public catalog.

MVP: — (parallel track; not on the app critical path)

---

## Scope

**In:**
- Landing page: the pitch ("Bring LEGO sets back from a pile of bricks"), the 4-step
  workflow, feature highlights, premium tease, App Store / Play badges.
- Legal: privacy policy (important — clarify the local-first "your data stays on your
  phone" story), terms.
- Basic SEO/OG, responsive, fast (SSG).
- Optional: a small "browse sets" teaser reading the **public catalog** (anon client) to
  show the app's data breadth.

**Out:** user auth on the web, any user data, the app itself, a full catalog browser (that's the app's job).

---

## Tasks

### 8.1 Scaffold
- `apps/web` — Next.js **16** (App Router, TypeScript, Tailwind). Already placeholder'd in [01](01-foundation.md). Reuse whatabrick's `apps/web` config shape (Next 16.2.x, React 19) as reference, minus all the AI/back-office code.
- Deploy target: Vercel (SSG/ISR). Domain TBD.

### 8.2 Content
- Hero + value prop, the four workflow steps (Select → Collect → Review → Finish) as illustrated cards, feature grid (inventory collection, verification report, missing-parts export, cloud sync, party mode), premium section, FAQ, footer.
- Wireframe-first here too, matched to the app's design trajectory ([09](09-design-polish-and-future.md)); polish alongside the app's rebrand.

### 8.3 Catalog teaser (optional)
- A read-only `catalogClient` (anon key, whatabrick project) via `@supabase/ssr` to render a "explore 27,000+ sets" strip or a searchable teaser. Public read only; no writes, no user data. Reuse whatabrick's `packages/shared` client pattern.

### 8.4 Store presence
- App Store / Play Store badges + links (once the app has listings), OG images, sitemap, analytics (privacy-respecting).

---

## Acceptance criteria

- [ ] `pnpm --filter web build` green; Lighthouse performance/SEO ≥ 90.
- [ ] Landing communicates the 4-step workflow and the premium split clearly.
- [ ] Privacy policy accurately describes local-first storage + optional premium sync.
- [ ] (If built) catalog teaser reads public data with the anon key only.

---

## Dependencies & risks

- Only depends on [01](01-foundation.md) scaffold; content can start immediately.
- **Risk:** privacy copy must match the actual data model (local-first; nothing leaves the device without premium sign-in) — keep it truthful.
- **Low risk overall** — fully decoupled from the app; safe to hand to a parallel worker.
