-- ============================================================
-- queries.sql
-- SQL Dialect : SQLite 3
-- Run order   : after setup.sql, in the SAME database file
--               sqlite3 outputs/support.db < sql/queries.sql
-- SLA rule    : breach = resolution_hours > 24 (exactly 24 meets SLA)
-- ============================================================

.headers on
.mode csv

-- ------------------------------------------------------------
-- S2a — Average resolution time by department (JOIN tickets -> teams)
-- Returns: department, avg_resolution_hours, ordered DESC
-- ------------------------------------------------------------
.once outputs/sql/s2a_avg_resolution_by_department.csv
SELECT
    te.department                                         AS department,
    ROUND(AVG(t.resolution_hours), 2)                     AS avg_resolution_hours
FROM tickets t
JOIN teams te ON t.team_id = te.team_id
GROUP BY te.department
ORDER BY avg_resolution_hours DESC;

-- ------------------------------------------------------------
-- S2b — Teams breaching SLA (GROUP BY + HAVING avg > 24)
-- ------------------------------------------------------------
.once outputs/sql/s2b_teams_breaching_sla.csv
SELECT
    te.team                                                AS team,
    te.department                                          AS department,
    ROUND(AVG(t.resolution_hours), 2)                      AS avg_resolution_hours
FROM tickets t
JOIN teams te ON t.team_id = te.team_id
GROUP BY te.team, te.department
HAVING AVG(t.resolution_hours) > 24
ORDER BY avg_resolution_hours DESC;

-- ------------------------------------------------------------
-- S2c — Top two channels by breach count (ties broken alphabetically)
-- ------------------------------------------------------------
.once outputs/sql/s2c_top_channels_by_breach.csv
SELECT
    channel,
    SUM(CASE WHEN resolution_hours > 24 THEN 1 ELSE 0 END) AS breach_count
FROM tickets
GROUP BY channel
ORDER BY breach_count DESC, channel ASC
LIMIT 2;

-- ------------------------------------------------------------
-- S3 — Data integrity check: every tickets.team_id must match
-- a teams.team_id (LEFT JOIN from teams to tickets — every fact
-- row resolves to a lookup row -> zero unmatched keys expected)
-- ------------------------------------------------------------
.once outputs/sql/diagnostic_unmatched_keys.csv
SELECT
    t.ticket_id,
    t.team_id AS tickets_team_id,
    te.team_id AS matched_lookup_team_id
FROM tickets t
LEFT JOIN teams te ON t.team_id = te.team_id
WHERE te.team_id IS NULL;
-- Expected result: 0 rows (empty file with header only) = zero unmatched keys.
