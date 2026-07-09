# BrickBack — Implementation Plan

> **Bring LEGO® sets back from a pile of bricks.**

This directory is the build plan. It turns [`../product-description.md`](../product-description.md)
into a sequenced, buildable roadmap. Start with **[00-architecture.md](00-architecture.md)** —
it's the spine every phase references.

> **▶ Resuming? Read [STATUS.md](STATUS.md) first** — the living "where are we" doc.
> **Phase 1 is complete (verified live on iOS sim). Phase 2 is next.**

---

## TL;DR

BrickBack is a **focused, mobile-first** re-do of the "rebuild" loop that already exists
inside the previous project [`whatabrick`](/Users/martynasjucys/Apps/whatabrick). We reuse
its Flutter patterns, its schema, and its live LEGO **catalog data** — but ship a lean app
that does one job well: **pick a set, count what you have, verify, export what's missing.**

- **Mobile:** Flutter (Riverpod + go_router + Drift + supabase_flutter) — same stack as whatabrick.
- **Web:** Next.js 16 marketing site.
- **Backend:** Supabase ×2 projects — a shared read-only **catalog** (the existing whatabrick DB, updated daily) and a new **user-data** project.
- **Data model:** local-first (Drift/SQLite); **cloud sync is the premium unlock**.
- **Design:** **wireframe-fidelity** through the MVP, then polished.

---

## Decision log

Locked with the user before planning:

| # | Decision | Choice | Consequence |
|---|---|---|---|
| D1 | Database topology | **Two Supabase projects** | Catalog is a shareable, isolated asset; ETL churn never touches user data. Local-first removes cross-DB join pain (see [00 §2](00-architecture.md#2-the-two-database-split)). |
| D2 | User-data storage | **Local-first; sync = premium** | Free tier = on-device Drift, works offline & needs no account. Premium = Supabase cross-device sync. |
| D3 | Repo layout | **Monorepo** | `apps/mobile` + `apps/web` + `services/` + `supabase/`, pnpm+turbo (Flutter nested, plain pub). |
| D4 | Catalog source | **Reuse the old whatabrick project directly** (`rgmmkhbeizdsyvwczigm`) | No re-backfill; connect read-only. Being trimmed to catalog-only. Its daily ETL already runs. Optionally lift the pipeline into this monorepo later ([07](07-catalog-pipeline-ownership.md)). |

**Supabase projects (real refs):** Catalog = `rgmmkhbeizdsyvwczigm` (whatabrick, premium
org, read-only, catalog-only after cleanup) · User data = `nthbhcqufiuyrnioxglm`
(BrickBack, "Martynas Free Plan", already created, MCP-reachable). Details in
[00 §2](00-architecture.md#2-the-two-database-split).

Defaulted by the plan (change any before building):

| # | Topic | Default | Where |
|---|---|---|---|
| D5 | Auth providers | Apple + Google + email OTP; **guest by default** (local-first needs no login) | [05](05-auth-and-cloud-sync.md) |
| D6 | Design fidelity | Wireframe token set now; swap to branded theme at Phase 9 | [01](01-foundation.md), [09](09-design-polish-and-future.md) |
| D7 | Monetization | Premium = cloud sync + unlimited projects + party mode; free = 1–3 local projects | [05](05-auth-and-cloud-sync.md) |
| D8 | Catalog pipeline ownership | Leave in whatabrick for MVP; lift into monorepo before public launch | [07](07-catalog-pipeline-ownership.md) |

---

## Phases

| Phase | File | Ships | MVP? |
|---|---|---|---|
| 0–1 | [01-foundation.md](01-foundation.md) | Monorepo scaffold, Flutter skeleton, two Supabase clients, wireframe design system, Drift + sync skeleton | ✅ |
| 2 | [02-catalog-and-set-selection.md](02-catalog-and-set-selection.md) | Catalog search, set detail, `expand_set_parts`, image CDN, "Add set" | ✅ |
| 3 | [03-inventory-collection.md](03-inventory-collection.md) | The core loop: tap-to-count grid, live progress, offline persistence, pause/resume | ✅ |
| 4 | [04-review-and-verification.md](04-review-and-verification.md) | Completion %, missing parts, minifig verify, verification report (image/PDF), BrickLink export | ✅ |
| 5 | [05-auth-and-cloud-sync.md](05-auth-and-cloud-sync.md) | Supabase auth, premium gating, cloud sync to the user project | — |
| 6 | [06-party-mode.md](06-party-mode.md) | Realtime collaborative sorting (premium) | — |
| 7 | [07-catalog-pipeline-ownership.md](07-catalog-pipeline-ownership.md) | Lift the Rebrickable ETL into `services/catalog-pipeline` | — |
| 8 | [08-marketing-site.md](08-marketing-site.md) | Next.js 16 marketing site | — |
| 9 | [09-design-polish-and-future.md](09-design-polish-and-future.md) | Wireframe→branded polish; set recognition, bag reconstruction, printable cert | — |

**Critical path to MVP:** 1 → 2 → 3 → 4. Phases 5–9 are independent follow-ups; **8
(marketing) can be built in parallel at any time** by anyone, since it only reads the
public catalog.

---

## How each phase file is structured

`Goal` · `Scope (in/out)` · `Deliverables` · `Tasks` · `Schema / code specifics (with
whatabrick reuse pointers)` · `Acceptance criteria` · `Dependencies & risks`.

## Open action items (user)

- [ ] Provide the **catalog** project's anon/publishable key + the R2 **CDN URL** → Phase 1 `.env`. (Ref/URL known; project not MCP-reachable.)
- [x] ~~Create the BrickBack user project~~ — already created (`nthbhcqufiuyrnioxglm`), MCP-reachable, URL + publishable key in [01 Env](01-foundation.md#env).
- [ ] Confirm D5–D7 defaults (auth providers, free/premium limits) before Phase 5.
- [ ] Consider upgrading the BrickBack org off the free plan before launch / party mode (free-tier limits; see [01 §1.2](01-foundation.md#12-supabase--user-project-already-created-nthbhcqufiuyrnioxglm)).
- [ ] Rebrickable API key only needed **if** we lift the pipeline (Phase 7).
