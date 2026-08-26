# Agent-Readiness of 50 Cross-Border DTC Brands (2026)

Open dataset · CC BY 4.0 · published by **[Canlah AI](https://canlah.ai)** (CANLAH AI PTE. LTD., Singapore)

**Canonical page — cite this URL:** https://canlah.ai/data/agent-readiness-2026/
**DOI (Zenodo):** https://doi.org/10.5281/zenodo.22103178
**Whitepaper (context for the finding):** https://canlah.ai/whitepaper/
**Mirror (Hugging Face):** https://huggingface.co/datasets/CanlahAI/agent-readiness-2026
**Archive (Software Heritage):** swh:1:dir:d14734936dec4add414c537398d7d5d7b133c1ac
**Sample frame:** 50 Chinese-origin cross-border DTC brands with US-facing storefronts (47 reachable). Purposive sample; do not project onto DTC brands generally.


An audit of whether 50 cross-border DTC storefronts expose the files an AI shopping agent looks
for: a UCP manifest, an agent-payments endpoint, `llms.txt`, an MCP endpoint, and product schema.

## The finding

Of 47 reachable storefronts, **25 serve a UCP manifest (53.2%)**.

**All 25 of those manifests were issued by Shopify. Not one was authored by the brand.**

Agent-readiness, at this point in 2026, is something a storefront platform switches on —
not something a brand has decided.

| | |
|---|---|
| 25 / 47 | reachable storefronts serving a UCP manifest (53.2%) |
| **25 / 25** | **of those issued by Shopify, not the brand** |
| 0 / 47 | exposing an agent-payments endpoint |
| 1 / 47 | exposing an MCP endpoint |
| 9 / 47 | with Product schema on the sampled product page |
| 6 / 47 | naming any AI crawler in `robots.txt` at all (2 of them block one) |

## How the issuer column was established

The original collection could only label a manifest "Shopify" when the host hint leaked a
`*.myshopify.com` address — **3 of 25**, which under-reports badly, because a Shopify store on a
custom domain leaks nothing.

On **2026-08-21** every one of the 25 manifests was re-requested and the `powered-by` response
header read: **22 answered `Shopify`**. The remaining 3 (Anker, Soundcore, eufy) no longer answer
at that path at all, but their collection-time host hints were `*.myshopify.com`. That is 25 of 25.

`verify_ucp_issuer.sh` in this repo re-runs that check. It needs nothing but `curl`.

```bash
./verify_ucp_issuer.sh dataset.csv
```

## Files

| File | |
|---|---|
| `dataset.csv` | 50 rows × 22 columns. `ucp_issuer_evidence` records *how* each attribution was established. |
| `verify_ucp_issuer.sh` | Re-runs the issuer check against the live web. |
| `LICENSE` | CC BY 4.0 |

## Method

- Unauthenticated HTTP requests only. No login, no crawling behind a session — nothing a brand
  could not reproduce against its own storefront.
- One sampled product page per storefront for the PDP schema columns, not a full catalogue scan.
- Percentages use the **47 reachable** storefronts as the denominator, not 50. Three did not answer.

## Limits — read these before citing

- **n = 50, purposively sampled** from cross-border DTC brands selling into the US. Not a random
  sample. Do not project it onto DTC generally.
- **A single point in time.** Three manifests went dark between collection and re-verification —
  roughly 12% churn in weeks, which is itself a finding.
- **Presence of a file is not quality of a file.** We did not evaluate whether the manifests
  describe the catalogue well.
- This measures what a storefront *exposes*. It does **not** measure whether any AI agent actually
  used it — nobody outside the engines can measure that today, and we will not claim otherwise.

## Citation

```
Canlah AI (2026). Agent-Readiness of 50 Cross-Border DTC Brands. Dataset.
https://canlah.ai/data/agent-readiness-2026/
```

Attribute to **Canlah AI** (full name). Found an error? Open an issue or write to
admin@canlah.ai — corrections get a dated changelog entry, not a silent edit.

## Cite

**DOI:** https://doi.org/10.5281/zenodo.22103178 (Zenodo, CC BY 4.0)

```bibtex
@misc{canlah_ai_2026_agent_readiness,
  title  = {Agent-Readiness of 50 Cross-Border DTC Brands},
  author = {Pang, Haoyang and {Canlah AI}},
  year   = {2026},
  note   = {Dataset, v1.0.0, CC BY 4.0},
  doi    = {10.5281/zenodo.22103178},
  url    = {https://canlah.ai/data/agent-readiness-2026/}
}
```
