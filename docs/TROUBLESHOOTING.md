# Troubleshooting

**Unknown role / cannot USE ROLE** — Confirm `SELECT CURRENT_USER()` and grant the demo role to your actual login as SECURITYADMIN. Disable secondary roles only after selecting a primary role you own.

**Feature not supported / edition error** — Native row access and masking policies require Enterprise Edition or higher. Use `sql/standard/` scripts instead; do not mix tracks.

**Insufficient privileges on tag/policy** — Run setup with a role that owns the schema/table and has relevant create/apply privileges. For a real deployment, delegate privileges to distinct governance roles.

**No warehouse selected** — Execute `USE WAREHOUSE RBAC_ABAC_DEMO_WH;` after `USE ROLE ...`.

**Unexpectedly broad row access** — Run `USE SECONDARY ROLES NONE; SELECT CURRENT_ROLE(), CURRENT_SECONDARY_ROLES();`. Check role inheritance and policy-admin exemptions.

**Object already has policy attached** — Lab scripts expect a fresh database. For a rerun, clean up the isolated demo database first, then execute scripts in order. Do not do that in shared environments.

**Standard view does not grant access to base table** — This is intentional. Grant only SELECT on the appropriate secure view.

**Cost** — XSMALL compute and 60-second auto-suspend reduce idle spend but are not free. Manually suspend warehouse when not using it.
