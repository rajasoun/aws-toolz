#!/usr/bin/env python3
"""
AWS Budget Reporter
"""

from __future__ import print_function

__author__ = "Raja Soundaramourty"
__version__ = "0.1.0"
__license__ = "MIT No Attribution"

import os
import argparse
import datetime
import logging
import subprocess

# AWS
import boto3.session

# .env File Loading
from dotenv import load_dotenv

# Data
import pandas as pd
from tabulate import tabulate

# Import Local Libraries
from libs import identity
from libs.cost_explorer import CostExplorer

BASE_DIR = (
    subprocess.Popen(["git", "rev-parse", "--show-toplevel"], stdout=subprocess.PIPE)
    .communicate()[0]
    .rstrip()
    .decode("utf-8")
)


class Bill:
    """Retrieves BillingInfo from AWS through CostExplorer API
    >>> bill = Bill()
    >>> bill.process_cli_args()
    >>> costexplorer = Costexplorer
    >>> costexplorer.addReport(GroupBy=[{"Type": "DIMENSION","Key": "SERVICE"}])
    """

    def __init__(self):
        """Inirialization"""
        parser = argparse.ArgumentParser()
        parser.add_argument("--log", type=str, default="debug")
        parser.add_argument("--days", type=int, default=30)
        parser.add_argument("--profile", type=str, default="default")
        parser.add_argument(
            "--current_month", type=str, default="false"
        )  # Previous Month
        args = parser.parse_args()

        # Convert to upper case to allow the user to
        # specify --log=DEBUG or --log=debug
        log_level = getattr(logging, args.log.upper(), None)
        if not isinstance(log_level, int):
            msg = "Invalid log level: %s"
            raise ValueError(msg % args.log)
        logging.basicConfig(level=log_level)
        self.logger = logging.getLogger("cost-explorer")

        self.is_current_month = args.current_month
        if self.is_current_month.lower() == "true":
            self.is_current_month = True
        else:
            self.is_current_month = False

        self.aws_profile = args.profile
        now = datetime.datetime.utcnow()
        self.start = (now - datetime.timedelta(days=args.days)).strftime("%Y-%m-%d")
        self.end = now.strftime("%Y-%m-%d")
        self.report_path = (
            BASE_DIR + "/cost-explorer/generated/" + self.aws_profile + "/"
        )
        load_dotenv()

    def get_aws_session(self, aws_profile):
        """Get AWS Session"""
        session = boto3.session.Session(
            profile_name=aws_profile,
            aws_access_key_id=os.environ["AWS_ACCESS_KEY_ID"],
            aws_secret_access_key=os.environ["AWS_SECRET_ACCESS_KEY"],
        )
        return session


def create_dir_for_reports(path):
    """Create Dir if not Exists"""
    # Check whether the specified path exists or not
    if not os.path.exists(path):
        # Create a new directory because it does not exist
        os.makedirs(path)
        print(path + " directory for reports is created!")


def format_report(costexplorer):
    """Format Report Array"""
    lines = []
    for report in costexplorer.reports:
        print("\n" + report["Name"])
        lines.append(
            tabulate(
                pd.read_csv(costexplorer.csv_file_name),
                headers="keys",
                tablefmt="psql",
                showindex=False,
            )
        )
    return lines


def print_report(reports):
    """Print Report Array to stdout"""
    for report in reports:
        print(report)


def main():
    """Entry Point"""
    bill = Bill()
    create_dir_for_reports(bill.report_path)
    session = bill.get_aws_session(bill.aws_profile)
    whoami_info = identity.whoami(session=session)
    print(identity.format_whoami(whoami_info))
    client = session.client("ce", "us-east-1")
    costexplorer = CostExplorer(client, CurrentMonth=False)
    costexplorer.addReport(
        bill.report_path,
        Name="Total",
        GroupBy=[],
        Style="Total",
        IncSupport=True,
        type="chart",
    )
    reports = format_report(costexplorer)
    print_report(reports)
    costexplorer.generate_excel(bill.report_path, CURRENT_MONTH=False)


if __name__ == "__main__":
    main()
