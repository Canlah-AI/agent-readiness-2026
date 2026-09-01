# Erratum — v1.0.1 → v1.0.2 (2026-09-01)

Two published claims were wrong. Both came from a single defect in this repository's own
verification script, and one of them (a churn rate) had already been quoted onward. This page
records what was wrong, why, what replaces it, and how to check the replacement yourself.

## What was wrong

The collection pipeline probes `/.well-known/ucp`. The verification script shipped in this
repository probed **`/.well-known/ucp.json`**. Those are not the same endpoint:

| Front end | `/.well-known/ucp` | `/.well-known/ucp.json` |
|---|---|---|
| Shopify edge | 200 | 200 (catch-all) |
| Self-hosted (Netlify / Next.js) | 200 | **404** |

So the script silently tested *"is this domain on Shopify's edge?"* rather than *"is the manifest
still served?"* Three brands (Anker, Soundcore, eufy) serve their manifest from their own front
end and were therefore recorded as gone.

| Claim (v1.0.0 – v1.0.1) | Status |
|---|---|
| "3 (Anker, Soundcore, eufy) no longer answer at that path at all" | **Withdrawn — false.** All three return 200 on `/.well-known/ucp`. |
| "~12% churn" (3 of 25 manifests no longer served) | **Withdrawn.** It was computed from the three false negatives above. |

## What replaces them

Re-run on 2026-09-01 against all 25, on the collection path, reading the manifest body:

- **25 of 25 are still served.** Manifest presence has not churned at all since collection.
- **25 of 25 cite a `*.myshopify.com` address inside the manifest body.** The headline finding —
  every manifest is platform-issued, none brand-authored — **survives, and is now better
  evidenced**: previously three of them rested on a collection-time host hint, and now all 25 are
  confirmed from live content.
- **A real change the boolean columns could not see:** 22 of 25 manifests are on version
  `2026-08-25`; the same 3 are still on `2026-04-08`. A platform-side rollout that three
  self-hosted front ends have not picked up.

That last point is the substantive lesson. A panel of boolean presence columns reports "nothing
happened" for a period in which 88% of the manifests were rewritten. Presence is the wrong
instrument for measuring change; version and content are.

## How this was found

Not by a reader. An adversarial pre-publication review — run because we were about to offer this
data to a newsletter writer who re-runs other people's numbers — compared the two scripts and
noticed the paths differed by four characters.

**We also got the first correction wrong.** On 2026-08-31 we fixed a *different* bug in the same
script (a row filter that matched `true` in any of 22 columns, so it tested 48 rows instead of 25)
and published v1.0.1 saying the corrected script now reproduced "22 Shopify + 3 no-longer-served =
25 of 25." It did reproduce that — because it was still probing the wrong path. **A fix that makes
a false number reproduce is worse than no fix**, and we published one.

## Verify it yourself

```bash
git clone https://github.com/Canlah-AI/agent-readiness-2026
cd agent-readiness-2026
./verify_ucp_issuer.sh dataset.csv     # 25 rows tested, 25 Shopify-issued, 0 gone
```

Or check a single case directly — the contrast is the whole story:

```bash
curl -sI https://www.anker.com/.well-known/ucp      | head -1   # 200
curl -sI https://www.anker.com/.well-known/ucp.json | head -1   # 404
curl -s  https://www.anker.com/.well-known/ucp | grep -o 'myshopify[^"]*' | head -1
```

`dataset.csv` is byte-identical to v1.0.0. No collected value changed; what changed is a
verification path, two claims derived from it, and one number we had to take back.

## If you quoted the 12% figure

It came from us, it is withdrawn, and the correct statement for the same window is that manifest
presence did not churn. We would rather you have that than a number that flattered our own
narrative about volatility.
