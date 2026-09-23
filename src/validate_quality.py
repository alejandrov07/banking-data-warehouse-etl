import os
import re
from datetime import datetime
 
import pandas as pd
 
DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data", "raw")
REPORT_DIR = os.path.join(os.path.dirname(__file__), "..", "data", "quality_reports")
 
CEDULA_PATTERN = re.compile(r"^\d{3}-\d{6}-\d{1}$")
EMAIL_PATTERN = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
PHONE_PATTERN = re.compile(r"^\d{3}-\d{3}-\d{4}$")
 
 
def load_raw():
    customers = pd.read_csv(os.path.join(DATA_DIR, "customers.csv"))
    products = pd.read_csv(os.path.join(DATA_DIR, "products.csv"))
    branches = pd.read_csv(os.path.join(DATA_DIR, "branches.csv"))
    dates = pd.read_csv(os.path.join(DATA_DIR, "dates.csv"))
    transactions = pd.read_csv(os.path.join(DATA_DIR, "transactions.csv"))
    return customers, products, branches, dates, transactions
 
 
def check_completeness(customers, transactions):
    """Rule: required fields cannot be null/empty."""
    issues = []
 
    required_customer_cols = ["Cedula", "Email", "Phone", "FullName"]
    for col in required_customer_cols:
        missing = customers[customers[col].isna() | (customers[col] == "")]
        for _, row in missing.iterrows():
            issues.append(
                {
                    "check": "completeness",
                    "table": "customers",
                    "key": row.get("CustomerID", row.get("CustomerKey")),
                    "detail": f"Missing required field: {col}",
                }
            )
 
    required_txn_cols = ["CustomerKey", "ProductKey", "DateKey", "BranchKey", "Amount"]
    for col in required_txn_cols:
        missing = transactions[transactions[col].isna()]
        for idx, _ in missing.iterrows():
            issues.append(
                {
                    "check": "completeness",
                    "table": "transactions",
                    "key": f"row {idx}",
                    "detail": f"Missing required field: {col}",
                }
            )
 
    return issues
 
 
def check_validity(customers, transactions):
    """Rule: fields must match an expected format/range, not just be non-null."""
    issues = []
 
    for _, row in customers.iterrows():
        cedula = str(row["Cedula"])
        if not CEDULA_PATTERN.match(cedula):
            issues.append(
                {
                    "check": "validity",
                    "table": "customers",
                    "key": row["CustomerID"],
                    "detail": f"Cedula '{cedula}' does not match expected format NNN-NNNNNN-N",
                }
            )
        email = str(row["Email"])
        if not EMAIL_PATTERN.match(email):
            issues.append(
                {
                    "check": "validity",
                    "table": "customers",
                    "key": row["CustomerID"],
                    "detail": f"Email '{email}' is not a valid email format",
                }
            )
        phone = str(row["Phone"])
        if not PHONE_PATTERN.match(phone):
            issues.append(
                {
                    "check": "validity",
                    "table": "customers",
                    "key": row["CustomerID"],
                    "detail": f"Phone '{phone}' does not match expected format NNN-NNN-NNNN",
                }
            )
 
    bad_amount = transactions[transactions["Amount"] <= 0]
    for idx, row in bad_amount.iterrows():
        issues.append(
            {
                "check": "validity",
                "table": "transactions",
                "key": f"row {idx}",
                "detail": f"Amount {row['Amount']} is not a positive value",
            }
        )
 
    bad_qty = transactions[transactions["Quantity"] <= 0]
    for idx, row in bad_qty.iterrows():
        issues.append(
            {
                "check": "validity",
                "table": "transactions",
                "key": f"row {idx}",
                "detail": f"Quantity {row['Quantity']} is not a positive value",
            }
        )
 
    return issues
 
 
def check_consistency(customers, products, branches, dates, transactions):
    """Rule: foreign keys in FACT_Transaction must exist in their dimension."""
    issues = []
 
    valid_customers = set(customers["CustomerKey"])
    valid_products = set(products["ProductKey"])
    valid_branches = set(branches["BranchKey"])
    valid_dates = set(dates["DateKey"])
 
    fk_checks = [
        ("CustomerKey", valid_customers, "DIM_Customer"),
        ("ProductKey", valid_products, "DIM_Product"),
        ("BranchKey", valid_branches, "DIM_Branch"),
        ("DateKey", valid_dates, "DIM_Date"),
    ]
 
    for col, valid_set, dim_name in fk_checks:
        orphan_rows = transactions[~transactions[col].isin(valid_set)]
        for idx, row in orphan_rows.iterrows():
            issues.append(
                {
                    "check": "consistency",
                    "table": "transactions",
                    "key": f"row {idx}",
                    "detail": f"{col}={row[col]} has no matching record in {dim_name}",
                }
            )
 
    return issues
 
 
def check_duplicates(customers, transactions):
    """
    Rule: detect duplicate customers using Cedula as the golden key
    (a real national ID should map to exactly one customer record),
    and detect duplicate transactions (same customer/product/date/
    branch/amount/type repeated, which would double-count activity).
    """
    issues = []
 
    dup_cedula = customers[customers.duplicated(subset=["Cedula"], keep=False)]
    for cedula, group in dup_cedula.groupby("Cedula"):
        customer_ids = ", ".join(group["CustomerID"].astype(str))
        issues.append(
            {
                "check": "duplicate",
                "table": "customers",
                "key": cedula,
                "detail": f"Cedula (golden key) appears on multiple CustomerIDs: {customer_ids}",
            }
        )
 
    dup_cols = ["CustomerKey", "ProductKey", "DateKey", "BranchKey", "Amount", "TransactionType"]
    dup_txn = transactions[transactions.duplicated(subset=dup_cols, keep=False)]
    for _, group in dup_txn.groupby(dup_cols):
        issues.append(
            {
                "check": "duplicate",
                "table": "transactions",
                "key": str(dict(zip(dup_cols, group.iloc[0][dup_cols]))),
                "detail": f"{len(group)} transactions share the same customer/product/date/branch/amount/type",
            }
        )
 
    return issues
 
 
def write_report(all_issues, totals):
    os.makedirs(REPORT_DIR, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    report_path = os.path.join(REPORT_DIR, f"quality_report_{timestamp}.md")
 
    lines = ["# Data Quality Report", "", f"Generated: {datetime.now().isoformat()}", ""]
    lines.append("## Summary")
    lines.append("")
    lines.append(f"- Customers scanned: {totals['customers']}")
    lines.append(f"- Transactions scanned: {totals['transactions']}")
    lines.append(f"- Total issues found: {len(all_issues)}")
    lines.append("")
 
    by_check = {}
    for issue in all_issues:
        by_check.setdefault(issue["check"], []).append(issue)
 
    for check_name in ["completeness", "validity", "consistency", "duplicate"]:
        group = by_check.get(check_name, [])
        lines.append(f"## {check_name.capitalize()} ({len(group)} issues)")
        lines.append("")
        if not group:
            lines.append("No issues found.")
        else:
            for issue in group:
                lines.append(f"- [{issue['table']}] key={issue['key']}: {issue['detail']}")
        lines.append("")
 
    with open(report_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
 
    return report_path
 
 
def main():
    customers, products, branches, dates, transactions = load_raw()
 
    all_issues = []
    all_issues += check_completeness(customers, transactions)
    all_issues += check_validity(customers, transactions)
    all_issues += check_consistency(customers, products, branches, dates, transactions)
    all_issues += check_duplicates(customers, transactions)
 
    totals = {"customers": len(customers), "transactions": len(transactions)}
    report_path = write_report(all_issues, totals)
 
    print(f"Scanned {totals['customers']} customers and {totals['transactions']} transactions.")
    print(f"Found {len(all_issues)} data quality issues.")
    print(f"Full report written to: {report_path}")
 
 
if __name__ == "__main__":
    main()
