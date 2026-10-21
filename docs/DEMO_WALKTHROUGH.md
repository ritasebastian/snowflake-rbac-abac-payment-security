# Interview/demo walkthrough (10–15 minutes)

1. **Architecture (2 min):** Explain warehouse/database/schema/table and role grants. Use synthetic payments across US, EU and APAC.
2. **RBAC (2 min):** `SHOW GRANTS TO ROLE DEMO_US_ANALYST;` Demonstrate SELECT without UPDATE/DELETE.
3. **Row filtering (3 min):** Under `DEMO_US_ANALYST`, count 3; under `DEMO_EU_ANALYST`, count 3; under `DEMO_AUDITOR`, count 8.
4. **ABAC (3 min):** Point to `DATA_CLASSIFICATION='PII'` on `CUSTOMER_EMAIL` and the tag-attached masking policy. Switch auditor/compliance to show masked/clear.
5. **Least privilege (2 min):** Explain why governance mapping table isn't directly selectable by analyst, and why `USE SECONDARY ROLES NONE` matters.
6. **Operations (2 min):** Show `SHOW ROW ACCESS POLICIES`, `SHOW MASKING POLICIES`, auto-suspend, and cleanup.

## Screenshots to collect
- `01_edition_and_setup.png`: Snowsight edition/setup (hide organization/account identifiers)
- `02_role_grants.png`: US role grants
- `03_us_three_rows.png`: US analyst three masked rows
- `04_eu_three_rows.png`: EU analyst three masked rows
- `05_auditor_all_masked.png`: Auditor eight masked rows
- `06_compliance_all_visible.png`: Compliance eight rows (synthetic only)
- `07_tag_policy.png`: tag + masking policy SQL/object metadata

Store under `assets/screenshots/` and reference screenshots in README.
Do not capture real emails, access tokens, account URL, or credentials.

## Talking points
- **RBAC** controls *whether* an active role can access a table/view.
- **Row access policy** checks user/session-role attributes and transaction-region attributes for *which rows*.
- **Tag-based masking** uses the object's data-classification attribute and role entitlement for *which columns/values*.
- **Standard fallback** does not implement native dynamic tag-based ABAC; it uses distinct secure views per audience.
