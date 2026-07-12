# M2 AI Story Spike

Prove: **Dolch prompt → backend proxy → mini-tier model → story text**

## Prerequisites

1. Team API key from **private Canvas announcement** (not class-wide post)
2. Node 20+
3. Copy `.env.example` → `.env` and set `GEMINI_API_KEY`

## Run locally (before Firebase deploy)

```bash
cd "/Users/joshpage/4150 Project"
cp .env.example .env
# Edit .env — paste key from Canvas
node scripts/m2_story_spike.mjs
```

Success writes `docs/milestone2/spike/spike_result_latest.json` (no secrets in file).

## Run against deployed function

```bash
firebase deploy --only functions:generateStorySpike
# Call from Firebase shell or curl with callable protocol
```

## Dolch words used (default spike)

Pre-Primer sample: `a, and, big, blue, can, come, down, find, for, funny`

Override: `DOLCH_WORDS="I,see,the,dog,run" node scripts/m2_story_spike.mjs`

## Evidence for video

Show terminal JSON `story` field + explain proxy path (see `BACKEND_PROXY_ARCHITECTURE.md`).
