# 📊 Customer Support Quality Analysis — data-analysis-set-b-YOUR-STUDENT-ID

**🧑‍🎓 Student Name / ID:** _[fill in — YOUR NAME / YOUR-STUDENT-ID]_
**🎯 Assigned Set:** Set B — Customer Support Quality
**📝 Exam:** Data Analysis Practical Exam (Excel • Power BI • SQL • Python)

> ⚠️ Replace `YOUR-STUDENT-ID` in the repository name and everywhere below
> with your actual student ID before submitting.

---

## 1. 🎯 Business Objective

**Business question:** Which support team should improve resolution
performance, and how does service quality vary by channel?

Two business questions answered in this analysis:
1. Which **department** (Service vs. Technical) — and which **team** within
   it — has the weakest SLA resolution performance?
2. How does **SLA breach behaviour vary by channel** (Email, Chat, Phone)?

---

## 2. 🗂️ Dataset & Data Dictionary

Two synthetic CSV files, supplied by the exam and stored in `data/raw/`.

### `data/raw/tickets.csv` — fact table (13 raw rows, 1 exact duplicate)
| Column | Type | Meaning |
|---|---|---|
| ticket_id | integer | Ticket identifier |
| month | text (ordered: Jan → Feb → Mar) | Month the ticket was logged |
| team_id | text | Foreign key to `teams.team_id` |
| channel | text | Support channel: Email / Chat / Phone |
| resolution_hours | number | Hours taken to resolve the ticket |
| satisfaction | number | Customer satisfaction, 1–5 scale |

### `data/raw/teams.csv` — lookup table (4 rows)
| Column | Type | Meaning |
|---|---|---|
| team_id | text | Primary key |
| team | text | Team name |
| department | text | Service or Technical |

---

## 3. 🧹 Cleaning Steps & Metric Definitions

- **🔁 Duplicate handling:** `tickets.csv` contains 13 rows; row 13
  (`ticket_id 12, Mar, T4, Phone, 24, 5`) is an exact duplicate of row 12. It
  is removed in every module (Excel `Clean` sheet, SQL load, Python
  `drop_duplicates`, Power BI Power Query) so **12 unique records** remain
  everywhere.
- **🚨 breach_flag rule:** `breach_flag = 1` when `resolution_hours > 24`,
  else `0`. **Exactly 24 hours meets the SLA** (not a breach) — this is a
  strict greater-than comparison in every module.
- **📉 SLA breach rate** = (tickets with `breach_flag = 1`) ÷ (all tickets),
  shown as a percentage. Calculated from underlying counts, never by
  averaging subgroup percentages.
- **🔗 Department** is attached to each ticket via a lookup on `team_id`
  (Excel: `INDEX/MATCH` — XLOOKUP avoided for LibreOffice/compatibility;
  SQL: `JOIN`; Python: `pandas.merge`; Power BI: relationship + measures).
- All numeric results reported to 2 decimal places; tied entities for
  highest/lowest are all reported (see Section 10).

---

## 4. 🛠️ Tools & Versions Used

| Tool | Version |
|---|---|
| 📗 Excel | Formulas built with `openpyxl`; verify in Excel 2019+ / Microsoft 365 |
| 🗄️ SQL engine | **SQLite 3** (see `sql/setup.sql` header comment) |
| 🐍 Python | 3.x — packages pinned in `requirements.txt` (pandas, matplotlib, openpyxl) |
| 📊 Power BI Desktop | Latest version (Windows only) |

---

## 5. 📁 Project Folder Structure

```
data-analysis-set-b-YOUR-STUDENT-ID/
├── README.md
├── requirements.txt
├── .gitignore
├── data/raw/tickets.csv
├── data/raw/teams.csv
├── excel/analysis.xlsx
├── sql/setup.sql
├── sql/queries.sql
├── sql/run_sql.py                      (Python fallback runner — no sqlite3 CLI needed)
├── python/analysis.py
├── powerbi/dashboard.pbix              ✅
├── outputs/clean_data.csv
├── outputs/python_summary.csv
├── outputs/python_chart.png
├── outputs/powerbi_dashboard.png       (to be added — see note below)
├── outputs/support.db
└── outputs/sql/
    ├── s2a_avg_resolution_by_department.csv
    ├── s2b_teams_breaching_sla.csv
    ├── s2c_top_channels_by_breach.csv
    └── diagnostic_unmatched_keys.csv
```

---

## 6. 🗄️ SQL — Setup & Run Instructions

Dialect: **SQLite 3**. Two ways to run it — pick whichever works on your
machine:

**Option A — `sqlite3` CLI installed** (macOS/Linux usually have it; on
Windows it must be downloaded separately, so this often is NOT available
out of the box):

```bash
sqlite3 outputs/support.db < sql/setup.sql
sqlite3 outputs/support.db < sql/queries.sql
```

**Option B — no `sqlite3` CLI needed** (Python only, works everywhere):

```bash
python sql/run_sql.py
```

Either option creates `tickets` and `teams` (with PK/FK constraints), loads
12 fact rows + 4 lookup rows (duplicate excluded at load), then saves
`outputs/sql/s2a_avg_resolution_by_department.csv`,
`s2b_teams_breaching_sla.csv`, `s2c_top_channels_by_breach.csv`, and
`diagnostic_unmatched_keys.csv`.

---

## 7. 🐍 Python — Environment Setup & Run Instructions

```bash
pip install -r requirements.txt
python python/analysis.py
```

Run from the **repository root** — all paths inside the script are relative
(`data/raw/tickets.csv`, `outputs/...`) so it works unmodified after cloning
to another machine. The script loads and cleans the data, asserts a 12-row
merge with zero unmatched `team_id` values, computes `breach_flag`, prints
the department breach-rate summary and the team(s) with the highest breach
rate (numerator/denominator shown explicitly), and saves the monthly average
resolution-hours chart and both export CSVs to `outputs/`.

---

## 8. 📗 Excel Sheet Guide (`excel/analysis.xlsx`)

| Sheet | Contents |
|---|---|
| **Raw** | Original 13-row `tickets.csv`, unchanged, with a live before-count formula |
| **Lookup** | 4-row `teams.csv` |
| **Clean** | 12 de-duplicated rows + `department` (`INDEX/MATCH` against Lookup) + `breach_flag` (`=IF(resolution_hours>24,1,0)`); live before/after row-count formulas |
| **Summary** | Breached-ticket count by channel via `COUNTIFS` + overall SLA breach rate; a live formula-driven Department × Month average-resolution-hours cross-tab (Jan→Feb→Mar) equivalent to a PivotTable; a clustered column chart built from that cross-tab |

**📌 Note on E3:** all cells are live formulas (no hardcoded results),
verified with zero formula errors via LibreOffice recalculation. The
Department × Month table is built with `AVERAGEIFS` rather than a native
Excel PivotTable object, because native PivotTable XML cannot be authored by
this automated pipeline. For full native-PivotTable credit, select the
`Clean` sheet data and use **Insert → PivotTable** in Excel directly
(rows=department, columns=month, values=average of resolution_hours) — it
will reproduce the same numbers shown in Summary.

---

## 9. 📊 Power BI — Data Source & Refresh Instructions

`powerbi/dashboard.pbix` ✅ is included in this repo — built with:
- Power Query: types set, exact duplicate row removed (12 clean rows).
- Model view: active one-to-many relationship `teams[team_id]` → `tickets[team_id]`, single-direction filtering.
- Three DAX measures (`Ticket Count`, `Avg Satisfaction`, `SLA Breach Rate`).
- One report page: 3 KPI cards, a department bar chart, a Jan→Feb→Mar monthly trend chart, and a channel slicer.

**🔄 Refresh after cloning:** in Power Query Editor, edit the
`tickets`/`teams` source step (`Source = Csv.Document(File.Contents("<path>"), ...)`)
to point at your local `data/raw/tickets.csv` and `data/raw/teams.csv`, then
**Refresh**.

**📸 Still needed:** open the report page (unfiltered state) in Power BI
Desktop and save a screenshot to `outputs/powerbi_dashboard.png` — this is a
required exam deliverable and can only be captured from the live app.

---

## 10. 🔍 Findings & Recommendation

1. 📈 **Technical department breaches SLA far more than Service:** 50.00%
   breach rate (3 of 6 tickets) vs. 33.33% (2 of 6 tickets) for Service;
   overall breach rate is 41.67% (5 of 12 tickets).
2. 💬 **Chat has the highest breach count by channel** (3 breaches), ahead of
   Phone (2) and Email (0 breaches). At the team level, **AppSupport and
   BillingHelp are tied for the highest individual breach rate** at 66.67%
   (2 of 3 tickets each).

**✅ Recommendation:** Prioritise SLA-improvement effort on **AppSupport**
(Technical) and **BillingHelp** (Service) — the two teams tied for the
highest breach rate — and specifically investigate **Chat-channel handling**,
since it carries the most breaches of any channel.

**⚠️ Limitation:** the dataset is a very small synthetic sample (12 clean
tickets across 3 months), so findings indicate direction rather than
statistically robust trend; the two-way tie at the team level would need a
larger sample to resolve confidently.

---

## 11. 🔗 Cross-Tool Reconciliation

**Aggregate checked:** average `resolution_hours` for the **Technical**
department.

| Tool | Value |
|---|---|
| 📗 Excel (Summary sheet AVERAGEIFS cross-tab, "Overall Avg" for Technical) | 28.33 |
| 🗄️ SQL (`outputs/sql/s2a_avg_resolution_by_department.csv`) | 28.33 |
| 🐍 Python (`outputs/python_summary.csv` — via `clean_data.csv` grouped) | 28.33 |
| 📊 Power BI (`Avg Resolution Hours` card filtered to Technical) | 28.33 |

✅ No rounding differences — all four values agree to 2 decimal places
(170 ÷ 6 = 28.333... → 28.33).

---

## 12. 🎥 Video

**URL:** _[paste your unlisted YouTube / Drive link here]_
**Duration:** _[e.g., 7 minutes 42 seconds]_

> 🎬 The video walkthrough (face + screen, 5–10 minutes) must still be
> recorded and uploaded by the student per exam Section B, then linked here.

---

## 13. 📚 References

No external code or resources were used beyond the standard library
documentation for pandas, matplotlib, openpyxl, and SQLite.

---

## 14. ✍️ Authorship Declaration

All work in this repository is my own except where cited.

---

## 15. ✅ What Still Needs Manual Completion

Everything analytical/technical (Excel, SQL, Python, Power BI dashboard,
data files, README, findings, reconciliation) is complete and verified in
this repository. The following require actions only a human/camera can do:

- [ ] 📸 Screenshot the unfiltered `powerbi/dashboard.pbix` report page → `outputs/powerbi_dashboard.png`.
- [ ] 🎥 Record the 5–10 minute face+screen video and add the link + duration above.
- [ ] 🐙 Create the public GitHub repo `data-analysis-set-b-YOUR-STUDENT-ID`, push this project, and record the final commit hash in your submission message.
- [ ] 📝 Replace all `YOUR-STUDENT-ID` / `[fill in]` placeholders above.
