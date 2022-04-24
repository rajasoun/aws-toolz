#!/usr/bin/env python3

"""
Cost Explorer Report
"""

__author__ = "Raja Soundaramourty"
__version__ = "0.1.0"
__license__ = "MIT No Attribution"

# system
import os
import sys
import subprocess

# utils
import datetime
import logging
from dateutil.relativedelta import relativedelta

# aws
import boto3

# data
import pandas as pd

# Required to load modules from vendored subfolder (for clean development env)
sys.path.append(os.path.join(os.path.dirname(os.path.realpath(__file__)), "./vendored"))

# GLOBALS
ACCOUNT_LABEL = os.environ.get("ACCOUNT_LABEL")
if not ACCOUNT_LABEL:
    ACCOUNT_LABEL = "Email"

CURRENT_MONTH = os.environ.get("CURRENT_MONTH")
if CURRENT_MONTH == "true":
    CURRENT_MONTH = True
else:
    CURRENT_MONTH = False

LAST_MONTH_ONLY = os.environ.get("LAST_MONTH_ONLY")

BASE_DIR = (
    subprocess.Popen(["git", "rev-parse", "--show-toplevel"], stdout=subprocess.PIPE)
    .communicate()[0]
    .rstrip()
    .decode("utf-8")
)

# Default exclude support, as for Enterprise Support
# as support billing is finalised later in month so skews trends
INC_SUPPORT = os.environ.get("INC_SUPPORT")
if INC_SUPPORT == "true":
    INC_SUPPORT = True
else:
    INC_SUPPORT = False

# Default include taxes
INC_TAX = os.environ.get("INC_TAX")
if INC_TAX == "false":
    INC_TAX = False
else:
    INC_TAX = True

TAG_VALUE_FILTER = os.environ.get("TAG_VALUE_FILTER") or "*"
TAG_KEY = os.environ.get("TAG_KEY")


class CostExplorer:
    """Retrieves BillingInfo checks from CostExplorer API"""

    def __init__(self, client=None, current_month=False):
        # Array of reports ready to be output to Excel.
        self.csv_file_name = None
        self.reports = []
        self.client = client
        if self.client is None:
            self.client = boto3.client("ce", region_name="us-east-1")

        self.end = datetime.date.today().replace(day=1)
        self.riend = datetime.date.today()
        if current_month or CURRENT_MONTH:
            self.end = self.riend

        if LAST_MONTH_ONLY:
            # 1st day of month a month ago
            self.start = (datetime.date.today() - relativedelta(months=+1)).replace(
                day=1
            )
        else:
            # Default is last 12 months
            # 1st day of month 12 months ago
            self.start = (datetime.date.today() - relativedelta(months=+12)).replace(
                day=1
            )

        # 1st day of month 11 months ago
        self.ristart = (datetime.date.today() - relativedelta(months=+11)).replace(
            day=1
        )
        # 1st day of month 6 months ago, so RI util has savings values
        self.sixmonth = (datetime.date.today() - relativedelta(months=+6)).replace(
            day=1
        )
        self.accounts = {}

    def add_report(
        self,
        report_dir,
        report_name="Default",
        group_by=None,
        report_style="Total",
        no_credits=True,
        credits_only=False,
        refund_only=False,
        upfront_only=False,
        include_support=False,
        include_tax=True,
        report_type="chart",
    ):
        """Add Report"""
        if group_by is None:
            group_by = [
                {"Type": "DIMENSION", "Key": "SERVICE"},
            ]
        results = []
        if not no_credits:
            response = self.client.get_cost_and_usage(
                TimePeriod={
                    "Start": self.start.isoformat(),
                    "End": self.end.isoformat(),
                },
                Granularity="MONTHLY",
                Metrics=[
                    "UnblendedCost",
                ],
                GroupBy=group_by,
            )
        else:
            report_filter = {"And": []}

            Dimensions = {
                "Not": {
                    "Dimensions": {
                        "Key": "RECORD_TYPE",
                        "Values": ["Credit", "Refund", "Upfront", "Support"],
                    }
                }
            }
            if (
                INC_SUPPORT or include_support
            ):  # If global set for including support, we dont exclude it
                Dimensions = {
                    "Not": {
                        "Dimensions": {
                            "Key": "RECORD_TYPE",
                            "Values": ["Credit", "Refund", "Upfront"],
                        }
                    }
                }
            if credits_only:
                Dimensions = {
                    "Dimensions": {
                        "Key": "RECORD_TYPE",
                        "Values": [
                            "Credit",
                        ],
                    }
                }
            if refund_only:
                Dimensions = {
                    "Dimensions": {
                        "Key": "RECORD_TYPE",
                        "Values": [
                            "Refund",
                        ],
                    }
                }
            if upfront_only:
                Dimensions = {
                    "Dimensions": {
                        "Key": "RECORD_TYPE",
                        "Values": [
                            "Upfront",
                        ],
                    }
                }
            # If filtering Record_Types and Tax excluded
            if "Not" in Dimensions and (not INC_TAX or not include_tax):
                Dimensions["Not"]["Dimensions"]["Values"].append("Tax")

            tagValues = None
            if TAG_KEY:
                tagValues = self.client.get_tags(
                    SearchString=TAG_VALUE_FILTER,
                    TimePeriod={
                        "Start": self.start.isoformat(),
                        "End": datetime.date.today().isoformat(),
                    },
                    TagKey=TAG_KEY,
                )

            if tagValues:
                report_filter["And"].append(Dimensions)
                if len(tagValues["Tags"]) > 0:
                    Tags = {"Tags": {"Key": TAG_KEY, "Values": tagValues["Tags"]}}
                    report_filter["And"].append(Tags)
            else:
                report_filter = Dimensions.copy()

            response = self.client.get_cost_and_usage(
                TimePeriod={
                    "Start": self.start.isoformat(),
                    "End": self.end.isoformat(),
                },
                Granularity="MONTHLY",
                Metrics=[
                    "UnblendedCost",
                ],
                GroupBy=group_by,
                Filter=report_filter,
            )

        if response:
            results.extend(response["ResultsByTime"])

            while "nextToken" in response:
                nextToken = response["nextToken"]
                response = self.client.get_cost_and_usage(
                    TimePeriod={
                        "Start": self.start.isoformat(),
                        "End": self.end.isoformat(),
                    },
                    Granularity="MONTHLY",
                    Metrics=[
                        "UnblendedCost",
                    ],
                    GroupBy=group_by,
                    NextPageToken=nextToken,
                )

                results.extend(response["ResultsByTime"])
                if "nextToken" in response:
                    nextToken = response["nextToken"]
                else:
                    nextToken = False
        rows = []
        sort = ""
        for v in results:
            row = {"date": v["TimePeriod"]["Start"]}
            sort = v["TimePeriod"]["Start"]
            for i in v["Groups"]:
                key = i["Keys"][0]
                if key in self.accounts:
                    key = self.accounts[key][ACCOUNT_LABEL]
                row.update({key: float(i["Metrics"]["UnblendedCost"]["Amount"])})
            if not v["Groups"]:
                row.update({"Total": float(v["Total"]["UnblendedCost"]["Amount"])})
            rows.append(row)

        df = pd.DataFrame(rows)
        df.set_index("date", inplace=True)
        df = df.fillna(0.0)

        if report_style == "Change":
            dfc = df.copy()
            lastindex = None
            for index, row in df.iterrows():
                if lastindex:
                    for i in row.index:
                        try:
                            df.at[index, i] = dfc.at[index, i] - dfc.at[lastindex, i]
                        except:
                            logging.exception("Error")
                            df.at[index, i] = 0
                lastindex = index
        df = df.sort_values(by=["date"], ascending=False)
        self.reports.append({"Name": report_name, "Data": df.T, "Type": report_type})
        self.csv_file_name = report_dir + report_name.lower() + ".csv"
        df.to_csv(self.csv_file_name, sep=",", encoding="utf-8")

    def generate_excel(self, report_dir, current_month=False):
        """Generate Excel Report"""
        excel_file = report_dir + "report.xlsx"
        writer = pd.ExcelWriter(excel_file, engine="xlsxwriter")
        workbook = writer.book
        for report in self.reports:
            print(report["Name"], report["Type"])
            report["Data"].to_excel(writer, sheet_name=report["Name"])
            worksheet = writer.sheets[report["Name"]]
            if report["Type"] == "chart":
                # Create a chart object.
                chart = workbook.add_chart({"type": "column", "subtype": "stacked"})
                chartend = 12
                if current_month:
                    chartend = 13
                for row_num in range(1, len(report["Data"]) + 1):
                    chart.add_series(
                        {
                            "name": [report["Name"], row_num, 0],
                            "categories": [report["Name"], 0, 1, 0, chartend],
                            "values": [report["Name"], row_num, 1, row_num, chartend],
                        }
                    )
                chart.set_y_axis({"label_position": "low"})
                chart.set_x_axis({"label_position": "low"})
                worksheet.insert_chart("O2", chart, {"x_scale": 2.0, "y_scale": 2.0})
        writer.save()


def main():
    """Entry Point"""
    costexplorer = CostExplorer(current_month=False)
    report_path = BASE_DIR + "/cost-explorer/generated/" + "secops-experiments" + "/"
    # Default addReport has filter to remove Support / Credits / Refunds / UpfrontRI / Tax
    # Overall Billing Reports
    costexplorer.add_report(
        report_path,
        report_name="Total",
        group_by=[],
        report_style="Total",
        include_support=True,
    )

    for report in costexplorer.reports:
        print("\n" + report["Name"])
        df = pd.read_csv(costexplorer.csv_file_name)
        print(df)
    costexplorer.generate_excel(report_path, current_month=False)
    return "Report Generated"


if __name__ == "__main__":
    main()
