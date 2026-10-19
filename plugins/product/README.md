# product

Product discovery, user research and product strategy skills and commands.

Install it per project, so it loads only where you do product work:

```
/plugin install product --marketplace shubh3794/claude-code-portable --scope project
```

Vendored from [phuryn/pm-skills](https://github.com/phuryn/pm-skills) at commit `07b34f6`
(MIT, © Pawel Huryn — see `LICENSE`): the `pm-product-discovery`, `pm-market-research`
and `pm-product-strategy` plugins, merged into one.

| Area | Skills | Commands |
|---|---|---|
| User research & discovery | interview-script, summarize-interview, opportunity-solution-tree, identify/prioritize-assumptions, brainstorm-ideas/experiments, analyze-feature-requests, prioritize-features, metrics-dashboard | `/interview`, `/discover`, `/brainstorm`, `/triage-requests`, `/setup-metrics` |
| User thinking & market | user-personas, user-segmentation, customer-journey-map, market-segments, market-sizing, competitor-analysis, sentiment-analysis | `/research-users`, `/competitive-analysis`, `/analyze-feedback` |
| Strategy | product-strategy, product-vision, value-proposition, lean-canvas, startup-canvas, business-model, monetization-strategy, pricing-strategy, swot-analysis, pestle-analysis, porters-five-forces, ansoff-matrix | `/strategy`, `/value-proposition`, `/business-model`, `/pricing`, `/market-scan` |

To update: re-copy those three plugins' `skills/` and `commands/` from upstream and bump the commit above.
