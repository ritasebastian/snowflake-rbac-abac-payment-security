# Snowflake Architecture — Complete Guide Using Your RBAC + ABAC Project

I'll explain the five main Snowflake objects—Database, Schema, Warehouse, Role, and User—using your project:

[snowflake-rbac-abac-payment-security](https://github.com/ritasebastian/snowflake-rbac-abac-payment-security?utm_source=chatgpt.com)

The explanation covers what each object does, why you created it, how they interact, and how to inspect them using SQL.

## 1. Snowflake architecture overview

In simple terms:

| Object    | Purpose                            | Your project            |
| --------- | ---------------------------------- | ----------------------- |
| Database  | Organizes stored data objects      | `RBAC_ABAC_DEMO`        |
| Schema    | Groups tables and other objects    | `DATA`, `GOVERNANCE`    |
| Warehouse | Supplies compute for queries       | `RBAC_ABAC_DEMO_WH`     |
| Role      | Defines permissions                | `DEMO_US_ANALYST`, etc. |
| User      | Identity that signs into Snowflake | Your Snowflake login    |

One important distinction: Databases and schemas organize your data. Warehouses process queries. Roles decide permissions. Users receive roles.

## 2. Database

A Snowflake database is a logical container for schemas, tables, views, and other database objects.

Your project creates one user-defined database:

`RBAC_ABAC_DEMO`

```

CREATE DATABASE IF NOT EXISTS RBAC_ABAC_DEMO;

```

Its structure is:

```
RBAC_ABAC_DEMO
├── DATA
│   └── PAYMENT_TRANSACTIONS
└── GOVERNANCE
    ├── REGION_ROLE_MAP
    ├── REGION_POLICY
    ├── DATA_CLASSIFICATION
    └── STRING_CLASSIFICATION_MASK
```

The database holds your project's data and security definitions. It does not represent a dedicated server.

To view databases:

```

SHOW DATABASES;

```

To select your database:

```

USE DATABASE RBAC_ABAC_DEMO;
SELECT CURRENT_DATABASE();

```

Snowflake also provides system-managed databases, such as `SNOWFLAKE`, for account metadata and other services. These are different from the database you created for the demo.

## 3. Schema

A schema is a logical namespace inside a database.

Your project uses two schemas.

`DATA`

Stores the payment transaction table used for analytics.

Fully qualified table name: `RBAC_ABAC_DEMO.DATA.PAYMENT_TRANSACTIONS`

`GOVERNANCE`

Stores security metadata and definitions, including row policies, masking policies, tags, and region-to-role mappings.

SQL to create both schemas:

```

CREATE SCHEMA IF NOT EXISTS RBAC_ABAC_DEMO.DATA;

CREATE SCHEMA IF NOT EXISTS RBAC_ABAC_DEMO.GOVERNANCE;

```

To view your schemas:

```

SHOW SCHEMAS IN DATABASE RBAC_ABAC_DEMO;

```

To view the transaction table:

```

SELECT *
FROM RBAC_ABAC_DEMO.DATA.PAYMENT_TRANSACTIONS;

```

### Why separate DATA and GOVERNANCE?

Because business data and security policies have different responsibilities.

For example, an analyst needs SELECT permission on the transaction table, but should not receive SELECT permission on the security mapping table `REGION_ROLE_MAP`.

Separating them makes the design easier to secure, maintain, and audit.

## 4. Warehouse

A Snowflake virtual warehouse provides compute resources to execute SQL queries.

Your project creates:

`RBAC_ABAC_DEMO_WH`

```

CREATE WAREHOUSE IF NOT EXISTS RBAC_ABAC_DEMO_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

```

| Property            | Meaning                                                |
| ------------------- | ------------------------------------------------------ |
| XSMALL              | Smallest standard warehouse size                       |
| AUTO_SUSPEND = 60   | Suspend after approximately 60 seconds of inactivity   |
| AUTO_RESUME = TRUE  | Resume automatically when a query needs compute        |
| INITIALLY_SUSPENDED | Do not start compute immediately on warehouse creation |

A warehouse doesn't store your tables; Snowflake stores the data separately.

The warehouse reads and processes data when you execute a query.

For example:

```

USE WAREHOUSE RBAC_ABAC_DEMO_WH;

SELECT COUNT(*)
FROM RBAC_ABAC_DEMO.DATA.PAYMENT_TRANSACTIONS;

```

Expected count before row-level policy filtering: 8 transactions.

To inspect your warehouse:

```

SHOW WAREHOUSES;

```

Free trial note: Warehouses consume trial credits while running, so auto-suspend is important.

## 5. Roles — RBAC

A role is a collection of permissions.

Snowflake uses Role-Based Access Control (RBAC) to determine what a user can do.

For example, a role may allow a user to read a table but not modify or delete it.

### Snowflake system roles

| Role            | Main responsibility                                               |
| --------------- | ----------------------------------------------------------------- |
| `ACCOUNTADMIN`  | Highest-level account administration                              |
| `SYSADMIN`      | Creating and managing warehouses, databases, and business objects |
| `SECURITYADMIN` | Managing security roles and grants                                |
| `USERADMIN`     | Creating and managing users and roles                             |
| `PUBLIC`        | Automatically available to all users                              |

Snowflake also has other specialized roles, but these are the main roles relevant to your demo.

### Custom roles in your project

You created five account roles in `02_roles_and_grants.sql`.

| Role              | Responsibility                           |
| ----------------- | ---------------------------------------- |
| `DEMO_US_ANALYST` | Analyze US transactions                  |
| `DEMO_EU_ANALYST` | Analyze EU transactions                  |
| `DEMO_AUDITOR`    | Review transactions from all regions     |
| `DEMO_PII_READER` | Entitlement to view unmasked PII         |
| `DEMO_COMPLIANCE` | Access all regions and view original PII |

You created the roles using SQL such as:

```

USE ROLE SECURITYADMIN;

CREATE ROLE IF NOT EXISTS DEMO_US_ANALYST;
CREATE ROLE IF NOT EXISTS DEMO_EU_ANALYST;
CREATE ROLE IF NOT EXISTS DEMO_AUDITOR;
CREATE ROLE IF NOT EXISTS DEMO_PII_READER;
CREATE ROLE IF NOT EXISTS DEMO_COMPLIANCE;

```

### How your role hierarchy works

In the SQL, `DEMO_PII_READER` is granted to `DEMO_COMPLIANCE`:

```

GRANT ROLE DEMO_PII_READER
TO ROLE DEMO_COMPLIANCE;

```

This means Compliance inherits the privileges of PII Reader.

The demo roles are also granted to `SYSADMIN` to facilitate administration. The reverse is not true: US Analyst does not inherit SYSADMIN.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.snowflake.com\&sz=32)

Snowflake Documentation

+1



### Which privileges does an analyst need?

To read payment transactions using the demo warehouse, the analyst needs:

| Object                     | Privilege | Why                       |
| -------------------------- | --------- | ------------------------- |
| Warehouse                  | `USAGE`   | Execute queries           |
| Database                   | `USAGE`   | Access database namespace |
| DATA schema                | `USAGE`   | Resolve objects in schema |
| PAYMENT_TRANSACTIONS table | `SELECT`  | Read records              |

Your SQL grants all four types.

For example:

```

GRANT USAGE ON WAREHOUSE RBAC_ABAC_DEMO_WH
TO ROLE DEMO_US_ANALYST;

GRANT USAGE ON DATABASE RBAC_ABAC_DEMO
TO ROLE DEMO_US_ANALYST;

GRANT USAGE ON SCHEMA RBAC_ABAC_DEMO.DATA
TO ROLE DEMO_US_ANALYST;

GRANT SELECT ON TABLE
RBAC_ABAC_DEMO.DATA.PAYMENT_TRANSACTIONS
TO ROLE DEMO_US_ANALYST;

```

Notice something important: granting SELECT to the analyst does not limit them to US rows. That restriction is enforced separately by your row access policy.

## 6. Users

A Snowflake user is an identity for a person or application that connects to Snowflake.

For example:

| User              | Assigned role     | Purpose                      |
| ----------------- | ----------------- | ---------------------------- |
| `ALICE_US`        | `DEMO_US_ANALYST` | US payment analytics         |
| `EMMA_EU`         | `DEMO_EU_ANALYST` | EU payment analytics         |
| `AUDIT_USER`      | `DEMO_AUDITOR`    | Audit reporting              |
| `COMPLIANCE_USER` | `DEMO_COMPLIANCE` | Sensitive-data investigation |

These are illustrative usernames, not users created by your current project.

Your existing scripts create the roles but deliberately leave user assignments as a manual step.

### Check your current login

```

SELECT
    CURRENT_USER() AS USER_NAME,
    CURRENT_ROLE() AS ACTIVE_ROLE,
    CURRENT_WAREHOUSE() AS WAREHOUSE_NAME,
    CURRENT_DATABASE() AS DATABASE_NAME,
    CURRENT_SCHEMA() AS SCHEMA_NAME;

```

### Assign a role to your existing Snowflake user

Run under `SECURITYADMIN` or another role authorized to grant it:

```

USE ROLE SECURITYADMIN;

GRANT ROLE DEMO_US_ANALYST
TO USER YOUR_SNOWFLAKE_USERNAME;

```

Replace `YOUR_SNOWFLAKE_USERNAME` with the value from `CURRENT_USER()`.

For your demonstration, you can grant all four testing roles to your login and switch roles to validate each security policy.

In production, give employees only the roles required for their responsibilities.

### Roles vs. users

Think of a bank:

- User = A bank employee.
- Role = Their job, such as teller or auditor.
- Privilege = What their job allows them to do, such as viewing an account.
- Policy = Additional restrictions, such as viewing only their branch's records.

A user can have multiple roles, but a role doesn't represent a person.

## 7. How RBAC and ABAC work together

In your project, RBAC and ABAC serve different purposes.

RBAC — Role-Based Access Control

Determines whether a role has permission to access an object.

ABAC — Attribute-Based Access Control

Makes an access decision based on attributes, such as the user's role, transaction region, or a column's data classification.

Your project demonstrates this through row access policies and tag-based masking.

### Row-level security

Your row access policy is:

`RBAC_ABAC_DEMO.GOVERNANCE.REGION_POLICY`

It reads the `MARKET_REGION` attribute and checks the role against `REGION_ROLE_MAP`.

```

SELECT MARKET_REGION, ROLE_NAME
FROM RBAC_ABAC_DEMO.GOVERNANCE.REGION_ROLE_MAP;

```

Expected mapping:

| MARKET_REGION | ROLE_NAME       |
| ------------- | --------------- |
| US            | DEMO_US_ANALYST |
| EU            | DEMO_EU_ANALYST |

The policy also permits auditors, compliance users, and the privileged SYSADMIN role to see every region.

### Column-level security

Your project protects:

`RBAC_ABAC_DEMO.DATA.PAYMENT_TRANSACTIONS.CUSTOMER_EMAIL`

It uses:

| Security object | Name                         | Purpose                     |
| --------------- | ---------------------------- | --------------------------- |
| Tag             | `DATA_CLASSIFICATION`        | Classifies column as PII    |
| Masking policy  | `STRING_CLASSIFICATION_MASK` | Hides protected values      |
| Role            | `DEMO_PII_READER`            | Permits original PII values |
| Column          | `CUSTOMER_EMAIL`             | Protected data              |

The masking policy checks both the classification tag and the user's active role hierarchy.

A normal analyst sees `***MASKED***`, while Compliance can view the original value.

### Complete expected access matrix

Choose a role to explore the expected behavior

US Analyst

EU Analyst

Auditor

Compliance

Visible transactions

# 3 / 8

Accessible regions

## US

Example email value

\*\*\*MASKED\*\*\*

Illustrative behavior based on your sample data and policy definitions; not a live Snowflake query.

## 8. SQL to inspect everything in your Snowflake account

This is useful for troubleshooting and GitHub evidence. Run it from a role with appropriate administrative or metadata visibility.

```

-- Current session context
SELECT
    CURRENT_USER(),
    CURRENT_ROLE(),
    CURRENT_WAREHOUSE(),
    CURRENT_DATABASE(),
    CURRENT_SCHEMA();

-- Databases
SHOW DATABASES;

-- Project schemas
SHOW SCHEMAS IN DATABASE RBAC_ABAC_DEMO;

-- Project tables
SHOW TABLES IN DATABASE RBAC_ABAC_DEMO;

-- Virtual warehouses
SHOW WAREHOUSES;

-- Account roles
SHOW ROLES;

-- Users (requires appropriate privileges)
SHOW USERS;

-- Roles assigned to current user
SHOW GRANTS;

-- Privileges assigned to a demo role
SHOW GRANTS TO ROLE DEMO_US_ANALYST;

-- Users or roles inheriting this role
SHOW GRANTS OF ROLE DEMO_US_ANALYST;

-- Table grants
SHOW GRANTS ON TABLE
RBAC_ABAC_DEMO.DATA.PAYMENT_TRANSACTIONS;

-- Row access policies
SHOW ROW ACCESS POLICIES
IN SCHEMA RBAC_ABAC_DEMO.GOVERNANCE;

-- Masking policies
SHOW MASKING POLICIES
IN SCHEMA RBAC_ABAC_DEMO.GOVERNANCE;

-- Tags
SHOW TAGS
IN SCHEMA RBAC_ABAC_DEMO.GOVERNANCE;

```

`SHOW GRANTS TO ROLE` shows privileges held by the role; `SHOW GRANTS OF ROLE` shows where the role has been assigned. These are useful commands during security audits.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.snowflake.com\&sz=32)

Snowflake Documentation



## 9. Where each object is defined in your project

| SQL script                          | Purpose                                                  |
| ----------------------------------- | -------------------------------------------------------- |
| `00_preflight.sql`                  | Check account configuration                              |
| `01_infrastructure.sql`             | Create warehouse, database, schemas, tables, sample data |
| `02_roles_and_grants.sql`           | Create custom roles and grant permissions                |
| `03_row_access.sql`                 | Implement row-level security                             |
| `04_abac_tag_masking.sql`           | Implement column-level masking                           |
| `05_test_cases.sql`                 | Test security using different roles                      |
| `07_validation_enterprise.sql`      | Validate Enterprise Edition policies                     |
| `08_column_level_masking_tests.sql` | Test email masking for each role                         |
| `standard/`                         | Alternative secure-view implementation                   |

## 10. Important architectural and security considerations

For an interview or production design, there are several details worth knowing.

- Warehouse isolation: Multiple roles can share one warehouse, as in your demo. Larger environments may dedicate warehouses to different workloads to isolate performance and costs.
- Role inheritance: The `SYSADMIN` role inherits your demo roles. Administrators can therefore have broader data access than regular analysts. Do not use an administrative role to prove analyst-only restrictions.
- Secondary roles: For accurate isolation testing, use `USE SECONDARY ROLES NONE` before activating the target role. Otherwise, other active entitlements may affect the results.
- PII protections: Masking hides values in query results for unauthorized roles, but does not encrypt or change the original column values.
- Project simplification: Your demo uses role membership as an attribute for row filtering. More advanced ABAC systems can use classification tags, mapping tables, department attributes, and business rules.

Snowflake's security system combines roles, object ownership, privileges, and security policies.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.snowflake.com\&sz=32)

Snowflake Documentation

+1



## 11. How to explain your project in an interview

**Snowflake RBAC and ABAC Security Implementation**

I designed a Snowflake data governance demonstration using a payment transaction dataset.

I created a dedicated database with separate DATA and GOVERNANCE schemas to isolate business information from security definitions.

I configured an X-Small virtual warehouse for query execution and created custom roles for US analysts, EU analysts, auditors, and compliance officers.

Using RBAC, I implemented least-privilege access through database, schema, warehouse, and table grants.

For row-level security, I implemented a row access policy that restricts transaction visibility based on market region and role membership.

For column-level security, I implemented classification tags and a dynamic data masking policy to protect customer email addresses.

Finally, I developed role-based validation queries to demonstrate that analysts only see authorized transactions with masked PII, while compliance officers can access all regions and original PII values.

The project demonstrates access control, role hierarchies, data governance, and sensitive-data protection in Snowflake.

The key concept to remember is:

User → Role → Privileges → Database/Schema/Table, with row access and masking policies applying additional controls when data is queried.

That relationship is the foundation of Snowflake access control and is especially important for Data Engineering and Snowflake security interviews.
