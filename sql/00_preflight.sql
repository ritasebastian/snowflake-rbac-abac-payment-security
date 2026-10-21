-- Execute in Snowsight; check your edition and current identity.
SELECT CURRENT_ACCOUNT() AS ACCOUNT_ID,
       CURRENT_USER() AS LOGIN_NAME,
       CURRENT_ROLE() AS ACTIVE_ROLE,
       CURRENT_SECONDARY_ROLES() AS SECONDARY_ROLES;
SELECT CURRENT_VERSION() AS SNOWFLAKE_VERSION;
-- ACCOUNTADMIN can check this parameter/edition in Snowsight > Admin > Accounts.
-- Enterprise+ is required for 03_row_access.sql and 04_abac_tag_masking.sql.
SHOW WAREHOUSES;
