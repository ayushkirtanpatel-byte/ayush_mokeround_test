-- ============================================================
-- setup.sql
-- SQL Dialect : SQLite 3 (tested on SQLite 3.4x, ships with Python's sqlite3 module)
-- Run order   : sqlite3 outputs/support.db < sql/setup.sql
--               sqlite3 outputs/support.db < sql/queries.sql
-- Purpose     : Create schema, load 12 clean fact rows + 4 lookup rows.
--               The 13th (duplicate) row from data/raw/tickets.csv is
--               intentionally EXCLUDED at load time, per exam rule.
-- ============================================================

DROP TABLE IF EXISTS tickets;
DROP TABLE IF EXISTS teams;

-- Lookup table: one row per support team
CREATE TABLE teams (
    team_id     TEXT PRIMARY KEY,
    team        TEXT NOT NULL,
    department  TEXT NOT NULL
);

-- Fact table: one row per support ticket
-- Foreign key: tickets.team_id -> teams.team_id
CREATE TABLE tickets (
    ticket_id         INTEGER PRIMARY KEY,
    month             TEXT NOT NULL,          -- Jan / Feb / Mar (ordered text category)
    team_id           TEXT NOT NULL,
    channel           TEXT NOT NULL,
    resolution_hours  NUMERIC NOT NULL,
    satisfaction      NUMERIC NOT NULL,        -- 1-5 scale
    FOREIGN KEY (team_id) REFERENCES teams(team_id)
);

PRAGMA foreign_keys = ON;

-- ---------- Load lookup data (4 rows) ----------
INSERT INTO teams (team_id, team, department) VALUES
('T1', 'AccountCare', 'Service'),
('T2', 'BillingHelp', 'Service'),
('T3', 'AppSupport',  'Technical'),
('T4', 'DeviceHelp',  'Technical');

-- ---------- Load fact data (12 clean rows — duplicate ticket_id 12 excluded) ----------
INSERT INTO tickets (ticket_id, month, team_id, channel, resolution_hours, satisfaction) VALUES
(1,  'Jan', 'T1', 'Email', 12, 4),
(2,  'Jan', 'T2', 'Chat',  28, 3),
(3,  'Jan', 'T3', 'Phone', 36, 2),
(4,  'Jan', 'T4', 'Email', 20, 4),
(5,  'Feb', 'T1', 'Chat',  8,  5),
(6,  'Feb', 'T2', 'Phone', 30, 3),
(7,  'Feb', 'T3', 'Email', 18, 4),
(8,  'Feb', 'T4', 'Chat',  40, 2),
(9,  'Mar', 'T1', 'Phone', 16, 4),
(10, 'Mar', 'T2', 'Email', 22, 4),
(11, 'Mar', 'T3', 'Chat',  32, 3),
(12, 'Mar', 'T4', 'Phone', 24, 5);

-- Sanity check counts (visible when run interactively)
-- SELECT COUNT(*) AS team_rows    FROM teams;    -- expect 4
-- SELECT COUNT(*) AS ticket_rows  FROM tickets;   -- expect 12
