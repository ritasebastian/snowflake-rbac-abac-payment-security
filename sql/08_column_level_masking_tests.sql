-- 08_column_level_masking_tests.sql
-- ENTERPRISE EDITION TRACK ONLY: Native tag-based dynamic data masking.
-- Prerequisites: run sql/01 through sql/04 and grant the four DEMO_* roles
-- to your own Snowflake user per sql/02_roles_and_grants.sql.
-- Run each section separately in Snowsight as the same test user.
-- IMPORTANT: secondary roles must be disabled to avoid extra permissions.
-- Expected numbers assume the original eight synthetic rows are unchanged.

USE SECONDARY ROLES NONE;

-- TEST A: US analyst sees three US rows and all emails masked.
USE ROLE DEMO_US_ANALYST;
USE WAREHOUSE RBAC_ABAC_DEMO_WH;
SELECT CURRENT_ROLE() AS ACTIVE_ROLE,
       TRANSACTION_ID, MARKET_REGION, CUSTOMER_NAME, CUSTOMER_EMAIL
FROM RBAC_ABAC_DEMO.DATA.PAYMENT_TRANSACTIONS
ORDER BY TRANSACTION_ID;
-- EXPECT: transaction IDs 1001, 1002, 1007; CUSTOMER_EMAIL = ***MASKED***.
SELECT CURRENT_ROLE() AS ACTIVE_ROLE,
       COUNT(*) AS VISIBLE_ROWS,
       COUNT_IF(CUSTOMER_EMAIL = '***MASKED***') AS MASKED_EMAILS,
       COUNT_IF(CUSTOMER_EMAIL <> '***MASKED***') AS UNMASKED_EMAILS
FROM RBAC_ABAC_DEMO.DATA.PAYMENT_TRANSACTIONS;
-- EXPECT: 3, 3, 0.

-- TEST B: EU analyst sees three EU rows and all emails masked.
USE ROLE DEMO_EU_ANALYST;
USE WAREHOUSE RBAC_ABAC_DEMO_WH;
SELECT CURRENT_ROLE() AS ACTIVE_ROLE,
       COUNT(*) AS VISIBLE_ROWS,
       COUNT_IF(CUSTOMER_EMAIL = '***MASKED***') AS MASKED_EMAILS
FROM RBAC_ABAC_DEMO.DATA.PAYMENT_TRANSACTIONS;
-- EXPECT: 3, 3.

-- TEST C: Auditor sees all eight rows, but email remains masked.
USE ROLE DEMO_AUDITOR;
USE WAREHOUSE RBAC_ABAC_DEMO_WH;
SELECT CURRENT_ROLE() AS ACTIVE_ROLE,
       COUNT(*) AS VISIBLE_ROWS,
       COUNT_IF(CUSTOMER_EMAIL = '***MASKED***') AS MASKED_EMAILS
FROM RBAC_ABAC_DEMO.DATA.PAYMENT_TRANSACTIONS;
-- EXPECT: 8, 8.

-- TEST D: Compliance sees all eight rows and original email values.
USE ROLE DEMO_COMPLIANCE;
USE WAREHOUSE RBAC_ABAC_DEMO_WH;
SELECT CURRENT_ROLE() AS ACTIVE_ROLE,
       TRANSACTION_ID, MARKET_REGION, CUSTOMER_EMAIL
FROM RBAC_ABAC_DEMO.DATA.PAYMENT_TRANSACTIONS
ORDER BY TRANSACTION_ID;
-- EXPECT: eight original @example.com email addresses.
SELECT CURRENT_ROLE() AS ACTIVE_ROLE,
       COUNT(*) AS VISIBLE_ROWS,
       COUNT_IF(CUSTOMER_EMAIL = '***MASKED***') AS MASKED_EMAILS,
       COUNT_IF(CUSTOMER_EMAIL LIKE '%@example.com') AS ORIGINAL_EMAILS
FROM RBAC_ABAC_DEMO.DATA.PAYMENT_TRANSACTIONS;
-- EXPECT: 8, 0, 8.

-- TEST E: Metadata check (run with a role that has tag metadata privileges).
-- The tag is configured in sql/04_abac_tag_masking.sql.
USE ROLE SYSADMIN;
SELECT SYSTEM$GET_TAG(
         'RBAC_ABAC_DEMO.GOVERNANCE.DATA_CLASSIFICATION',
         'RBAC_ABAC_DEMO.DATA.PAYMENT_TRANSACTIONS.CUSTOMER_EMAIL',
         'COLUMN'
       ) AS CUSTOMER_EMAIL_CLASSIFICATION;
-- EXPECT: PII.

-- Screenshot checklist (use only synthetic sample data):
-- assets/screenshots/01_us_analyst_email_masked.png
-- assets/screenshots/02_compliance_email_visible.png
-- Never capture or commit production customer PII or Snowflake credentials.
