# AGENTS.md

Guidelines for contributors (human or AI) working in **this** repository.

This repo is a thin orchestration layer over two pinned submodules. It does not
contain ArduPilot firmware or the Gazebo plugin source.

## Ground rules

- **Never edit files under `external/`.** Those are pinned submodules
  (`ardupilot`, `ardupilot_gazebo`). Change the pinned revision deliberately
  instead (see below) or upstream your change to the respective project.
- **Keep logic in `scripts/`.** The `Makefile` is a thin front-end; do not put
  build/run logic in it. Every target should shell out to a script.
- **One source of truth for paths/env**: `scripts/env.sh`. Source it; do not
  re-derive `GZ_SIM_*`, `AP_ROOT`, etc. elsewhere.
- **Python is managed by uv.** Add dependencies to `pyproject.toml` and run
  `uv sync` to update `uv.lock`. Never `pip install` into the venv by hand.
  Keep `empy` pinned to `==3.3.4` (ArduPilot's build/param parsing depends on it).
- **Config lives in `config/`**, not in the submodules. Param files go in
  `config/params/`, team worlds in `config/worlds/`, team models in
  `config/models/`.
- **`interfaces/contract.py` is a cross-team contract.** It is shared with the
  ground-station subteam. Any change that breaks the wire format must bump
  `CONTRACT_VERSION` and say so in the commit body. Keep it stdlib-only.
- **`fake_gs/` is a throwaway oracle.** It stands in for the not-yet-built
  ground station. Never add detection/perception logic there; delete it once
  the real ground station publishes the contract.

## Common tasks

| Goal | Do this |
|------|---------|
| Add a Python dependency | edit `pyproject.toml`, run `uv sync` |
| Add a make target | add the target to `Makefile` + a `scripts/*.sh`, mark `.PHONY` |
| Bump a submodule | `git -C external/ardupilot fetch && git -C external/ardupilot checkout <sha>` then commit; document why |
| Add team params/worlds | drop files in `config/params/` or `config/worlds/` |
| Add a team model | drop it in `config/models/<name>/` (uses `model://` deps) |
| Change the GS contract | edit `interfaces/contract.py` **and** `docs/interface.md`; bump `CONTRACT_VERSION` |

## Bumping a pinned submodule

```bash
git -C external/ardupilot fetch --tags
git -C external/ardupilot checkout <new-sha>
git add external/ardupilot
git commit -m "deps: bump ardupilot to <new-version>"
```

Rebuild and re-run `make doctor` afterwards, and note the change in the commit
body (why the bump, what was tested).

## Style

- Bash: `set -euo pipefail`, quote expansions, keep scripts runnable via
  `uv run scripts/<name>.sh`.
- Keep `make help` up to date (new targets need a `##` description comment).

## Do not

- Do not commit `.venv/`, build outputs, `.gz/`, or logs (see `.gitignore`).
- Do not hard-code absolute paths or a specific user's home directory.
- Do not put Gazebo installation steps into `make setup`; Gazebo is a
  per-developer prerequisite documented in `docs/`.
