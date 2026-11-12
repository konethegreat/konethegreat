# Phases

The working plan for the konethegreat profile README. Phases run in order; the tasks for each
phase are in [TASKS.md](TASKS.md) under the same heading, and every merged task adds one line to
[REPORT.md](REPORT.md).

The owner's standing direction applies to every phase: keep the design exactly as it is on GitHub
now (the self-hosted animated SVGs in `assets/`, the banner, typing line, cards, dividers, footer,
section order and styling), add no third-party image services, and change content only. A new
project card is only ever a copy of an existing card SVG with the same size, colours, fonts and
animation, with its text changed. Facts come only from `gh repo list konethegreat`, each
repository's README and GitHub releases, and the live sites. Every link and image path must
resolve. Credit stays with Kone Tshivhinda and K-ONE IT SOLUTIONS.

## Phase 1: Fix broken links and unsourced claims

The README links to `https://k-oneitsolutions.live/` twice, and that domain does not resolve
(NXDOMAIN). The same sentence still calls the K-ONE IT SOLUTIONS site "static HTML, CSS and
JavaScript", while its README now describes an Astro and Tailwind CSS site on Cloudflare Workers.
Two test counts in the project details ("20 tests" for ClearCut, "65 server tests" for SA-JAS)
are not shown in those repositories' READMEs. Fix these first, so the link check in Phase 2 starts
from a clean profile.

Done when: README.md no longer contains `k-oneitsolutions.live`, "20 tests" or "65 server tests",
and every http(s) URL in README.md returns a 2xx or 3xx status to `curl -L`, except the LinkedIn
URL, which answers automated clients with HTTP 999.

## Phase 2: Add link and design checks to CI

The only workflow is `.github/workflows/snake.yml`, which regenerates the contribution snake.
Nothing checks that links and image paths resolve, or that a change keeps the owner's direction.
Add a link and path check, and a small guard that fails on em or en dashes and on image hosts
other than the ones the profile uses today.

Done when: `.github/workflows/links.yml` and `.github/workflows/profile-guard.yml` exist on main,
and the latest run of each on main is `success` in `gh run list -R konethegreat/konethegreat`.

## Phase 3: Add AgentOS Studio to the profile

AgentOS Studio (`konethegreat/agentos-studio`) is public, its latest GitHub release is v1.2.3, and
its download site is live, but the profile does not mention it. The header's "Latest" badge still
points to ClearCut. Add AgentOS Studio as a text-only copy of an existing card, give it a details
entry, point the "Latest" badge at it, and cite it in the agent principles table where its README
supports the claim.

Done when: README.md shows `assets/card-agentos-studio.svg` in Selected projects, the "Latest"
badge links to `https://github.com/konethegreat/agentos-studio`, the details entry names release
1.2.3 (matching the `Latest` row of `gh release list -R konethegreat/agentos-studio`), and
`diff assets/card-munisolve.svg assets/card-agentos-studio.svg` shows changes only in text, the
status dot's `cx` and the animation delays.

## Phase 4: Bring the rest of the project list up to date

TimeLex (`konethegreat/timelex`, pre-alpha) is one of the five dossiers on the K-ONE IT SOLUTIONS
site but is not on the profile, and UI Vault, Reservoir, TimeLex v2 and two demo applications are
public without a mention. The SA-JAS details also omit its published browser extension release.
Add these from their READMEs and releases, without changing the existing cards.

Done when: README.md shows `assets/card-timelex.svg` in the fourth row of the projects table, every
repository linked from README.md is listed as PUBLIC by `gh repo list konethegreat --limit 200`,
and the links workflow passes on the pull request that adds the last of these entries.

## Phase 5: Refresh stack, About and README notes

The stack text and the scrolling tools row predate AgentOS Studio, the K-ONE site rebuild and
TimeLex v2, so Tauri, Astro, Tailwind CSS, Next.js and Vite are missing. The About paragraph does
not mention legal tech or multi-agent developer tooling, and the README header comment says the
profile uses no third-party image services while the header badges come from img.shields.io.
Update the content to match the sources, then run a full fact check.

Done when: the tools sentence in README.md, the chips in `assets/skills.svg` and its `<desc>`, and
the skills image alt text in README.md list the same tools; the header comment matches the
images README.md actually loads; and the final fact check task is ticked with a REPORT.md line.
