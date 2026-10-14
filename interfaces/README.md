# interfaces/

**The only surface shared between the interceptor team and the ground-station
subteam.**

The contract is expressed in standard **MAVLink** messages, so the two sides do
not share code:

- `contract.py` — the single source of truth for the numbers (ports, sysids,
  rates) described in `../docs/interface.md`. Both the ground station and the
  `fake_gs/` oracle import these values so they can never drift apart.
- `../docs/interface.md` — the human-readable contract (message set, payload,
  framing, update rate).

Rules:

- Changing anything here is a **breaking change** for the other subteam. Bump
  the `CONTRACT_VERSION` in `contract.py` and note it in the commit body.
- Keep `contract.py` dependency-free (stdlib only) so it can be vendored into
  the ground-station repo without dragging in this repo's environment.
