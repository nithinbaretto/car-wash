# Working in this repository

Read [README.md](README.md) first. It is the shared project context and includes
the component map, API contracts, completed work, deployment history, checks and
known gaps. Then read the relevant component README or linked contract.

- Inspect `git status` before edits; preserve existing work and local configuration.
- Keep real Firebase authentication, role/ownership checks, transactional slot
  reservations, idempotent retries and shop-review gates intact.
- Do not introduce runtime mock fallbacks or commit generated Firebase configs,
  API keys, credentials or debug logs. Local Firebase config setup is documented
  in `Frontend_app/Readme.md`.
- Run checks appropriate to the change. Separate local test success from actual
  deployment and device verification when reporting results.
- Update the root README when changing contracts, setup, deployment status or
  known limitations so the next agent can continue without re-investigating.
