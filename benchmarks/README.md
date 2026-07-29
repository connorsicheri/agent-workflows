# Compass Benchmarks

This suite compares Codex Compass, Claude Compass, and matched single-agent
baselines on small deterministic repositories. It measures whether delegation
actually reduces time to a correct result, and how much token or dollar usage it
adds.

The harness does not run model calls during validation or dry runs. An actual
`run` command consumes provider usage and may incur API or subscription costs.

## Tasks

| Task | Shape | Expected Codex Compass routing |
| --- | --- | --- |
| `01_localized_type_fix` | One annotation correction | Root only; no reviewer |
| `02_single_lane_pagination` | One focused behavioral bug | Root only |
| `03_parallel_module_fixes` | Three independent bugs | Parallel lanes with useful root work |
| `04_parallel_exporters` | Three independent implementations | Compact task graph and parallel implementers |
| `05_permission_boundary` | Permission-sensitive bug | Root implementation, strong review, formal verification |

Every task has:

- A disposable fixture repository.
- Public tests available to the agent.
- An external grader not copied into the fixture.
- Exact allowed and required changed-file rules.
- An expected Compass routing shape for trace inspection.

The tasks are intentionally short. The direct tasks expose agent startup and
workflow overhead; the parallel tasks provide enough independent work for
Compass to recover that overhead; the permission task checks whether expensive
review is reserved for a justified case.

## Profiles

The core comparison uses matched root model and effort where practical:

- `codex-single-sol-high`
- `codex-compass`
- `claude-single-sonnet-max`
- `claude-compass`

Additional single-agent profiles provide effort sweeps while keeping each
provider's root model pinned:

- Codex Sol at low, medium, and high.
- Claude Sonnet 5 1M at low, medium, and max.

Claude Compass retains the model and effort declared by its orchestrator agent.
Codex Compass uses its high-effort Sol root plus the models configured for its
specialists.

## Metrics

Each result records:

- Agent wall-clock time, external grading time, and combined time.
- Exit and timeout status.
- Public and hidden validation results.
- Changed files and scope compliance.
- Correctness: successful agent exit, all graders pass, only allowed files
  changed, and every required file changed.
- Configured root model and effort.
- Input, cached input, cache-creation input, output, and reasoning tokens when
  exposed.
- Total token estimate and provider-reported cost when available.
- Raw stdout, stderr, command, prompt, diff, and per-model usage data.

Codex JSONL reports `turn.completed` usage. The harness sums those events and
does not double-count cached input or reasoning tokens when computing total
tokens. A Codex multi-agent stream may not attribute every child turn to a model;
those tokens remain under `unattributed` instead of being guessed. Claude's JSON
result normally includes per-model usage and optional dollar cost.

Token totals are useful within one provider, but should not be treated as
identical units across providers because tokenization and accounting differ.
Likewise, subscription-backed Codex runs may not expose a dollar cost.

## Use

Validate manifests, fixtures, baseline failures, graders, and CLI availability:

```bash
python3 benchmarks/run.py validate --check-clis
```

Inspect the available matrix:

```bash
python3 benchmarks/run.py list
```

Preview commands without model calls:

```bash
python3 benchmarks/run.py run --profiles core --tasks all --repetitions 3 --dry-run
```

Run the core matrix three times in randomized, sequential order:

```bash
python3 benchmarks/run.py run \
  --profiles core \
  --tasks all \
  --repetitions 3
```

For Claude API-backed runs, optionally place a ceiling on each Claude run:

```bash
python3 benchmarks/run.py run \
  --profiles core \
  --tasks all \
  --repetitions 3 \
  --max-budget-usd 1.00
```

Run only the single-agent effort sweep:

```bash
python3 benchmarks/run.py run \
  --profiles codex-single-sol-low,codex-single-sol-medium,codex-single-sol-high,claude-single-sonnet-low,claude-single-sonnet-medium,claude-single-sonnet-max \
  --tasks all \
  --repetitions 3
```

Summarize correct runs with medians and Compass speedup against the matched
single-agent profile:

```bash
python3 benchmarks/run.py summarize
python3 benchmarks/run.py summarize --format csv --output benchmarks/results/summary.csv
python3 benchmarks/run.py summarize --format json --output benchmarks/results/summary.json
```

## Experimental protocol

For useful comparisons:

1. Record Codex, Claude, plugin, and repository versions before the matrix.
2. Use the same machine, account tier, checkout, and network conditions.
3. Run jobs sequentially; internal Compass parallelism is the variable under
   test, so parallel benchmark jobs would confound wall time.
4. Use at least three repetitions and compare medians. Five is preferable when
   provider variance is high.
5. Randomize order with the default seed, or choose and record another seed.
6. Compare time and tokens only among correct runs. Report failure rate beside
   performance so a fast incorrect run cannot win.
7. Inspect raw traces to verify expected routing. The harness scores outcomes,
   but it does not infer whether Compass selected the intended agents.
8. Re-run after meaningful prompt, model, or plugin changes rather than mixing
   configurations in one result set.

The fixture workspace is a fresh temporary Git repository for every run. It is
removed after grading unless `--keep-workspaces` is passed. Raw results remain
under `benchmarks/results/` and are ignored by Git.
