# Snowflake Architecture & Security — Reference Guide

> Reference for the [Snowflake RBAC + ABAC Payment Security Lab](../README.md).  Updated October 2026. This documents the **intended project configuration**, not a live inventory of your Snowflake account.

## 1. At a glance

| Object | What it does | Lab name |
|---|---|---|
| Database | Organizes schemas and data objects | `RBAC_ABAC_DEMO` |
| Schema | Namespace for tables, views, policies and tags | `DATA`, `GOVERNANCE` |
| Virtual warehouse | Compute to execute SQL; storage is separate | `RBAC_ABAC_DEMO_WH` |
| Role | Holds permissions/entitlements | Five `DEMO_*` roles |
| User | Login identity granted one or more roles | Your own login; no users created by the lab |

```
Snowflake account
├── Database: RBAC_ABAC_DEMO
│   ├── Schema: DATA
│   │   └── Table: PAYMENT_TRANSACTIONS (8 synthetic rows)
│   └── Schema: GOVERNANCE
│       ├── Table: REGION_ROLE_MAP
│       ├── Row access policy: REGION_POLICY [Enterprise track]
│       ├── Tag: DATA_CLASSIFICATION [Enterprise track]
│       └── Masking policy: STRING_CLASSIFICATION_MASK [Enterprise track]
├── Warehouse: RBAC_ABAC_DEMO_WH (XSMALL)
├── Roles: DEMO_US_ANALYST, DEMO_EU_ANALYST, DEMO_AUDITOR,
│          DEMO_PII_READER, DEMO_COMPLIANCE
└── Users: existing Snowflake login(s); grant roles manually
```

## 2. Database

`RBAC_ABAC_DEMO` is a logical data container, not a physical server. See [`sql/01_infrastructure.sql`](../sql/01_infrastructure.sql).

```sql
SHOW DATABASES;
SHOW SCHEMAS IN DATABASE RBAC_ABAC_DEMO;
USE DATABASE RBAC_ABAC_DEMO;
SELECT CURRENT_DATABASE();
```

## 3. Schemas

- `RBAC_ABAC_DEMO.DATA` contains the queryable transaction table, with `CUSTOMER_EMAIL` and `MARKET_REGION`.
- `RBAC_ABAC_DEMO.GOVERNANCE` holds the protected region-to-role mapping and security objects. Do **not** grant analysts direct `SELECT` on `REGION_ROLE_MAP`.
- On the Standard Edition fallback, see `sql/standard/` for its view-based architecture and additional schema objects.

```sql
SHOW TABLES IN SCHEMA RBAC_ABAC_DEMO.DATA;
SHOW TABLES IN SCHEMA RBAC_ABAC_DEMO.GOVERNANCE;
DESC TABLE RBAC_ABAC_DEMO.DATA.PAYMENT_TRANSACTIONS;
```

## 4. Warehouse

`RBAC_ABAC_DEMO_WH` runs queries but does **not** contain the stored data. Created XSMALL, auto-suspend after 60 seconds, and auto-resume enabled. Compute use consumes Snowflake credits.

```sql
SHOW WAREHOUSES;
USE WAREHOUSE RBAC_ABAC_DEMO_WH;
SELECT CURRENT_WAREHOUSE();
```

## 5. Roles and grants (RBAC)

From [`sql/02_roles_and_grants.sql`](../sql/02_roles_and_grants.sql):

| Role | Table access / business purpose | Expected Enterprise policy result |
|---|---|---|
| `DEMO_US_ANALYST` | Select payments for US analysis | US only (3 rows), masked email |
| `DEMO_EU_ANALYST` | Select payments for EU analysis | EU only (3 rows), masked email |
| `DEMO_AUDITOR` | Review payments across regions | All regions (8 rows), masked email |
| `DEMO_PII_READER` | PII visibility entitlement; **no direct table SELECT granted** | Not a standalone reporting role |
| `DEMO_COMPLIANCE` | Cross-region review and inherits PII reader | All regions (8 rows), original email |

The roles get `USAGE` on the warehouse, database and DATA schema plus `SELECT` on the transaction table (except PII Reader, which is an entitlement role). `DEMO_PII_READER` is granted **to** `DEMO_COMPLIANCE`. Demo roles are also granted **to** `SYSADMIN` for lab administration: that does not give analysts administrative privileges.

```sql
SHOW ROLES;
SHOW GRANTS TO ROLE DEMO_US_ANALYST;
SHOW GRANTS OF ROLE DEMO_US_ANALYST;
SHOW GRANTS TO ROLE DEMO_COMPLIANCE;
SHOW GRANTS ON TABLE RBAC_ABAC_DEMO.DATA.PAYMENT_TRANSACTIONS;
```

Snowflake system roles include `ACCOUNTADMIN`, `SECURITYADMIN`, `USERADMIN`, `SYSADMIN`, and `PUBLIC`. Prefer the least privilege needed for a task. `ACCOUNTADMIN` is not the default query role for routine analysis.

## 6. Users

The lab **does not create a new Snowflake user**. Grant relevant demo roles to your existing login (as a user/role administrator with the right privileges). Example:

```sql
SELECT CURRENT_USER(), CURRENT_ROLE();
-- Change the placeholder to the exact value of CURRENT_USER():
USE ROLE SECURITYADMIN;
GRANT ROLE DEMO_US_ANALYST TO USER YOUR_SNOWFLAKE_USERNAME;
-- For testing only, optionally grant the other demo roles to the same login.
```

A user is the identity authenticating to Snowflake; a role is a set of privileges. Multiple roles may be granted to one user. For isolated tests, explicitly use `USE SECONDARY ROLES NONE;` before switching primary roles.

## 7. Row-level ABAC: region attribute

[`sql/03_row_access.sql`](../sql/03_row_access.sql) applies `GOVERNANCE.REGION_POLICY` to the table's `MARKET_REGION` column. The policy checks role membership (`IS_ROLE_IN_SESSION`) and the secured `REGION_ROLE_MAP` table (US -> US Analyst, EU -> EU Analyst). Auditor, Compliance and SYSADMIN are intentionally exempted in this lab.

```sql
SHOW ROW ACCESS POLICIES IN SCHEMA RBAC_ABAC_DEMO.GOVERNANCE;
USE SECONDARY ROLES NONE;
USE ROLE DEMO_US_ANALYST;
USE WAREHOUSE RBAC_ABAC_DEMO_WH;
SELECT MARKET_REGION, COUNT(*) AS ROWS_VISIBLE
FROM RBAC_ABAC_DEMO.DATA.PAYMENT_TRANSACTIONS
GROUP BY MARKET_REGION;
-- Expected: US = 3
```

## 8. Column-level ABAC: PII tag + dynamic masking

[`sql/04_abac_tag_masking.sql`](../sql/04_abac_tag_masking.sql) creates `DATA_CLASSIFICATION` with `PUBLIC` and `PII` as allowed values, attaches the `STRING_CLASSIFICATION_MASK` policy to the tag, then tags `DATA.PAYMENT_TRANSACTIONS.CUSTOMER_EMAIL` as `PII`.

- Analyst or Auditor without a PII entitlement: `CUSTOMER_EMAIL` = `***MASKED***`.
- Compliance inherits `DEMO_PII_READER`: original synthetic email displayed.
- SYSADMIN is an explicit administrative exception in this training policy.

```sql
SHOW TAGS IN SCHEMA RBAC_ABAC_DEMO.GOVERNANCE;
SHOW MASKING POLICIES IN SCHEMA RBAC_ABAC_DEMO.GOVERNANCE;
USE SECONDARY ROLES NONE;
USE ROLE DEMO_US_ANALYST;
USE WAREHOUSE RBAC_ABAC_DEMO_WH;
SELECT TRANSACTION_ID, CUSTOMER_EMAIL
FROM RBAC_ABAC_DEMO.DATA.PAYMENT_TRANSACTIONS
ORDER BY TRANSACTION_ID;
-- Expected: three rows, each CUSTOMER_EMAIL = '***MASKED***'
```

For a repeatable matrix of checks, run [`sql/08_column_level_masking_tests.sql`](../sql/08_column_level_masking_tests.sql) in segments by role.

## 9. How everything interacts

1. **User** logs in and activates a **role**.
2. The role needs `USAGE` on the **warehouse**, **database**, and **schema**, plus `SELECT` on the **table**.
3. The **warehouse** provides compute for the query.
4. On the Enterprise track, the **row access policy** filters regions based on role membership.
5. The **masking policy** uses the column's classification tag and role membership to mask PII.

The expected 8 synthetic rows are distributed as US=3, EU=3, APAC=2. Results may differ if scripts were not run, roles were not granted, or secondary roles remain active.

## 10. Account inventory / troubleshooting queries

Run appropriate commands using a role authorized to view the objects. Some `SHOW` statements may list only objects visible to that role.

```sql
SELECT CURRENT_USER() AS USER_NAME,
       CURRENT_ROLE() AS ROLE_NAME,
       CURRENT_WAREHOUSE() AS WAREHOUSE_NAME,
       CURRENT_DATABASE() AS DATABASE_NAME,
       CURRENT_SCHEMA() AS SCHEMA_NAME;
SHOW DATABASES;
SHOW SCHEMAS IN DATABASE RBAC_ABAC_DEMO;
SHOW WAREHOUSES;
SHOW ROLES;
SHOW USERS;
SHOW GRANTS TO ROLE DEMO_US_ANALYST;
SHOW GRANTS OF ROLE DEMO_US_ANALYST;
SHOW ROW ACCESS POLICIES IN SCHEMA RBAC_ABAC_DEMO.GOVERNANCE;
SHOW MASKING POLICIES IN SCHEMA RBAC_ABAC_DEMO.GOVERNANCE;
SHOW TAGS IN SCHEMA RBAC_ABAC_DEMO.GOVERNANCE;
```

## 11. Edition and security notes

- Native row access policies, dynamic masking, and tag-based masking in this lab need **Snowflake Enterprise Edition or higher**. A Snowflake trial may provide Enterprise features depending on the edition selected.
- For **Standard Edition**, follow `sql/standard/` to demonstrate RBAC with secure views. That is not native ABAC, and you must not give the analyst direct SELECT on the underlying base table in that path.
- The examples use **synthetic data only**. Do not commit real user emails, account credentials, tokens, or unredacted production results.
- The policy intentionally grants broad access to `SYSADMIN` for this educational demo; use stricter separation-of-duties controls in production.

## 12. Interview-ready summary

> I built a Snowflake payment security lab with a dedicated database, separated DATA and GOVERNANCE schemas, and an XSMALL virtual warehouse. I defined least-privilege analyst, auditor and compliance roles; implemented row filtering by market region using role membership and a mapping table; and attached tag-based masking for customer emails. I validated the result with role-switching tests and documented both an Enterprise native policy track and a Standard Edition secure-view fallback.

## Related files

- [Project setup and execution order](../README.md)
- [Demo walkthrough](DEMO_WALKTHROUGH.md)
- [Troubleshooting](TROUBLESHOOTING.md)
- [Column masking test SQL](../sql/08_column_level_masking_tests.sql)
