# Starchitex — Multi-Branch Hotel Management System

Our database course term project Starchitex is a centralized PostgreSQL database for a hotel chain with multiple branches — one shared database instead of each branch keeping its own copies of everything. It covers reservations, check-in/check-out, billing, service requests, housekeeping, maintenance, role-based access control, and audit logging.

Team:
- Aung Kaung Thar (6780844) — database implementation, backend
- Elbin Ye Htet Naing (6781209) — RBAC & security design, frontend
- Min Linn Khant (6780839) — testing/QA, deployment, monitoring



Everything the project brief asks for lives in the **`database/`** folder:

- `database/ddl/` — the schema (tables, constraints, triggers)
- `database/seed/` — example data, 10+ rows per table
- `database/functions/` — the query functions, one `.sql` file each
- `database/tests/` — our test suite (integrity, workflows, RBAC)

The live database runs on render.com — the connection URL and credentials are in the submitted report (we keep them out of this repo since it's public).

The `backend/` and `frontend/` folders are a working Spring Boot prototype we built on top of the database. It's a bonus, not part of the required deliverables — the brief doesn't ask for an app, so please judge the project by the `database/` folder and the report.

## Rebuilding the database from scratch

If anything happens to the live database, the whole thing can be recreated from this repo:

```bash
psql "$DATABASE_URL" -f database/ddl/schema.sql
psql "$DATABASE_URL" -f database/seed/seed_data.sql
for f in database/functions/*.sql; do psql "$DATABASE_URL" -f "$f"; done
```

(`DATABASE_URL` is the external URL from Render — see the report.)

## Running the tests

```bash
for f in database/tests/*.sql; do psql "$DATABASE_URL" -f "$f"; done
```

Each test prints its own PASS/FAIL lines, so the output is readable on its own. The suite covers things like: double-booking gets rejected, invoices have to add up, checkout can't come before check-in, the audit log can't be edited, and each staff role can only do what its permissions allow (including not seeing other branches' data).




## Design highlights (full details in the report)

The schema is 26 normalized tables. Guest data is shared across branches while rooms, staff, and daily operations are branch-scoped. Access control works through a Role → Permission → RolePermission model (~35 granular permissions), the audit log is append-only, and the heavy queries (availability search, cross-branch occupancy, revenue reports) are indexed — the report shows the EXPLAIN ANALYZE numbers before and after.
