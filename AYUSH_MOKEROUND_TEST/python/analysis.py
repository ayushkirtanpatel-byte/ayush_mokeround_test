"""
analysis.py
Customer Support Quality Analysis — Task 3 (Python)

Run from the repository root:
    python python/analysis.py

All paths are relative to the repo root so this script runs unmodified
on another machine after `git clone`.
"""

import os
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# ------------------------------------------------------------------
# P1 — Load, Clean & Merge
# ------------------------------------------------------------------
TICKETS_PATH = "data/raw/tickets.csv"
TEAMS_PATH = "data/raw/teams.csv"
OUT_DIR = "outputs"
os.makedirs(OUT_DIR, exist_ok=True)

tickets = pd.read_csv(TICKETS_PATH)
teams = pd.read_csv(TEAMS_PATH)

# Confirm numeric types for resolution_hours and satisfaction
tickets["resolution_hours"] = pd.to_numeric(tickets["resolution_hours"])
tickets["satisfaction"] = pd.to_numeric(tickets["satisfaction"])

raw_row_count = len(tickets)  # expect 13

# Remove the exact duplicate row
tickets_clean = tickets.drop_duplicates(keep="first").reset_index(drop=True)
clean_row_count = len(tickets_clean)  # expect 12

print(f"Raw ticket rows   : {raw_row_count}")
print(f"Clean ticket rows : {clean_row_count} (duplicate removed)")
assert raw_row_count == 13, "Expected 13 raw rows in tickets.csv"
assert clean_row_count == 12, "Expected 12 rows after de-duplication"

# Merge tickets with teams on team_id (left join)
merged = tickets_clean.merge(teams, on="team_id", how="left")

assert len(merged) == 12, "Merged DataFrame must contain exactly 12 rows"
assert merged["department"].isna().sum() == 0, (
    "Every team_id in the fact file must match a lookup row "
    "(0 NaN values expected in department column)"
)
print("Merge check passed: 12 rows, 0 unmatched team_id values.")

# ------------------------------------------------------------------
# P2 — Derived Field & Department Analysis
# ------------------------------------------------------------------
# Exactly 24 hours meets the SLA (not a breach) -> strictly greater than 24
merged["breach_flag"] = (merged["resolution_hours"] > 24).astype(int)

department_summary = (
    merged.groupby("department")
    .agg(total_tickets=("ticket_id", "count"), breached=("breach_flag", "sum"))
    .reset_index()
)
department_summary["sla_breach_rate_pct"] = round(
    (department_summary["breached"] / department_summary["total_tickets"]) * 100, 2
)
department_summary = department_summary.sort_values(
    "sla_breach_rate_pct", ascending=False
).reset_index(drop=True)

# Team with the highest breach rate (report all ties)
team_summary = (
    merged.groupby("team")
    .agg(total_tickets=("ticket_id", "count"), breached=("breach_flag", "sum"))
    .reset_index()
)
team_summary["breach_rate_pct"] = round(
    (team_summary["breached"] / team_summary["total_tickets"]) * 100, 2
)
max_rate = team_summary["breach_rate_pct"].max()
top_teams = team_summary[team_summary["breach_rate_pct"] == max_rate]

overall_breach_rate = round((merged["breach_flag"].sum() / len(merged)) * 100, 2)

print("\nSLA breach summary by department:")
print(department_summary.to_string(index=False))
print(f"\nOverall SLA breach rate: {overall_breach_rate:.2f}% "
      f"({merged['breach_flag'].sum()} of {len(merged)} tickets)")
print("\nTeam(s) with the highest breach rate:")
for _, row in top_teams.iterrows():
    print(f"  {row['team']}: {int(row['breached'])} breached / "
          f"{int(row['total_tickets'])} total = {row['breach_rate_pct']:.2f}%")

# ------------------------------------------------------------------
# P3 — Chart & Exports
# ------------------------------------------------------------------
month_order = ["Jan", "Feb", "Mar"]
monthly_avg_resolution = (
    merged.groupby("month")["resolution_hours"]
    .mean()
    .reindex(month_order)
)

fig, ax = plt.subplots(figsize=(7, 5))
ax.bar(monthly_avg_resolution.index, monthly_avg_resolution.values, color="#C44E52")
ax.set_title("Average Resolution Hours by Month (Jan \u2192 Feb \u2192 Mar)")
ax.set_xlabel("Month")
ax.set_ylabel("Average Resolution Hours")
for i, v in enumerate(monthly_avg_resolution.values):
    ax.text(i, v, f"{v:,.2f}", ha="center", va="bottom")
fig.tight_layout()
fig.savefig(os.path.join(OUT_DIR, "python_chart.png"), dpi=150)
plt.close(fig)

# Export the clean merged DataFrame and the department summary
merged.to_csv(os.path.join(OUT_DIR, "clean_data.csv"), index=False)
department_summary.to_csv(os.path.join(OUT_DIR, "python_summary.csv"), index=False)

print(f"\nSaved chart  -> {OUT_DIR}/python_chart.png")
print(f"Saved data   -> {OUT_DIR}/clean_data.csv")
print(f"Saved summary-> {OUT_DIR}/python_summary.csv")
