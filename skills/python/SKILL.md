---
name: python
description: Python conventions and verification steps. Use when writing, reviewing or debugging Python code, including ML/training scripts.
---

# Python

## Before writing
- Find the toolchain: `pyproject.toml` (uv, poetry, hatch), `requirements*.txt`, or `setup.py`. Use the repo's runner (`uv run`, `poetry run`) rather than bare `python`.
- Check the target Python version and match existing typing style.

## Conventions
- Type hints on public functions; `from __future__ import annotations` only if the repo already uses it.
- `pathlib.Path` over `os.path`; context managers for files, locks and processes.
- Never bare `except:`; catch specific exceptions and re-raise with context (`raise X(...) from e`).
- No mutable default arguments. Prefer dataclasses / pydantic models over loose dicts for structured data.
- `logging` over `print` in library code.
- ML code: set and log seeds; keep device placement explicit (`.to(device)`); don't call `.item()` / `.cpu()` inside hot training loops; checkpoint model, optimizer, scheduler, RNG state and step together.
- Distributed (torch.distributed / DDP / FSDP): only rank 0 logs and writes checkpoints; every rank must hit the same collectives in the same order.

## Verify (run what the repo supports)
```bash
ruff check . && ruff format --check .   # or black/flake8 if that's what the repo uses
mypy <changed package>                  # if configured
pytest -q -x path/to/tests
```
