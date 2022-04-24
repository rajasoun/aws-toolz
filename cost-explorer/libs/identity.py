#!/usr/bin/env python3

"""Utility for determining what AWS account and identity you're using."""

__author__ = "Raja Soundaramourty"
__version__ = "0.1.0"
__license__ = "MIT No Attribution"

# system
import os
import sys
import argparse

# utils
import asyncio.log
import traceback
import json
from collections import namedtuple

# aws
from botocore.exceptions import ClientError
import botocore.session
import botocore

# Required to load modules from vendored subfolder (for clean development env)
sys.path.append(os.path.join(os.path.dirname(os.path.realpath(__file__)), "./vendored"))

WhoamiInfo = namedtuple(
    "WhoamiInfo",
    [
        "Account",
        "AccountAliases",
        "Arn",
        "Type",
        "Name",
        "RoleSessionName",
        "UserId",
        "Region",
        "SSOPermissionSet",
    ],
)

DESCRIPTION = """\
Show what AWS account and identity you're using.
Formats the output of sts.GetCallerIdentity nicely,
and also gets your account alias (if you're allowed)
"""


def main():
    """Entry Point"""
    parser = argparse.ArgumentParser(description=DESCRIPTION)
    parser.add_argument("--profile", help="AWS profile to use")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    parser.add_argument("--version", action="store_true")
    parser.add_argument("--debug", action="store_true")
    args = parser.parse_args()

    if args.version:
        print(__version__)
        parser.exit()

    try:
        session = botocore.session.Session(profile=args.profile)
        disable_account_alias = os.environ.get("AWS_WHOAMI_DISABLE_ACCOUNT_ALIAS", "")
        if disable_account_alias.lower() in ["", "0", "false"]:
            disable_account_alias = False
        elif disable_account_alias.lower() in ["1", "true"]:
            disable_account_alias = True
        else:
            disable_account_alias = disable_account_alias.split(",")
        whoami_info = whoami(
            session=session, disable_account_alias=disable_account_alias
        )

        if args.json:
            print(json.dumps(whoami_info._asdict()))
        else:
            print(format_whoami(whoami_info))
    except Exception as exception:
        if args.debug:
            traceback.print_exc()
        err_cls = type(exception)
        err_cls_str = err_cls.__name__
        if err_cls.__module__ != "builtins":
            format_msg = "{}.{}"
            err_cls_str = format_msg.format(err_cls.__module__, err_cls_str)
        error = "ERROR [{}]: {}\n"
        sys.stderr.write(error.format(err_cls_str, exception))
        sys.exit(1)


def format_whoami(whoami_info):
    """Format whoami info"""
    lines = [("Account: ", whoami_info.Account)]
    for alias in whoami_info.AccountAliases:
        lines.append(("", alias))
    lines.append(("Region: ", whoami_info.Region))
    if whoami_info.SSOPermissionSet:
        lines.append(("AWS SSO: ", whoami_info.SSOPermissionSet))
    else:
        type_str = "".join(p[0].upper() + p[1:] for p in whoami_info.Type.split("-"))
        whoami_line = "{}: "
        lines.append((whoami_line.format(type_str), whoami_info.Name))
    if whoami_info.RoleSessionName:
        lines.append(("RoleSessionName: ", whoami_info.RoleSessionName))
    lines.append(("UserId: ", whoami_info.UserId))
    lines.append(("Arn: ", whoami_info.Arn))
    max_len = max(len(line[0]) for line in lines)
    formatted_lines = "{}{}"
    return "\n".join(
        formatted_lines.format(line[0].ljust(max_len), line[1]) for line in lines
    )


def whoami(session=None, disable_account_alias: object = False):
    """Return a WhoamiInfo namedtuple.

    Args:
        session: An optional boto3 or botocore Session
        disable_account_alias (bool): Disable checking the account alias

    Returns:
        WhoamiInfo: Data on the current IAM principal, account, and region.

    """
    if session is None:
        session = botocore.session.get_session()

    data = {"Region": session.get_config_variable("region")}

    response = session.create_client("sts").get_caller_identity()

    for field in ["Account", "Arn", "UserId"]:
        data[field] = response[field]

    data["Type"], name = data["Arn"].rsplit(":", 1)[1].split("/", 1)

    if data["Type"] == "assumed-role":
        data["Name"], data["RoleSessionName"] = name.rsplit("/", 1)
    else:
        data["Name"] = name
        data["RoleSessionName"] = None

    if data["Type"] == "assumed-role" and data["Name"].startswith("AWSReservedSSO"):
        try:
            # format is AWSReservedSSO_{permission-set}_{random-tag}
            data["SSOPermissionSet"] = data["Name"].split("_", 1)[1].rsplit("_", 1)[0]
        except Exception as exception:
            data["SSOPermissionSet"] = None
            asyncio.log.logger.critical(exception)
    else:
        data["SSOPermissionSet"] = None

    data["AccountAliases"] = []
    if not isinstance(disable_account_alias, bool):
        for value in disable_account_alias:
            if data["Account"].startswith(value) or data["Account"].endswith(value):
                disable_account_alias = True
                break
            fields = ["Name", "Arn", "RoleSessionName"]
            if any(value == data[field] for field in fields):
                disable_account_alias = True
                break
    if not disable_account_alias:
        try:
            # pedantry
            paginator = session.create_client("iam").get_paginator(
                "list_account_aliases"
            )
            for response in paginator.paginate():
                data["AccountAliases"].extend(response["AccountAliases"])
        except ClientError as exception:
            if exception.response.get("Error", {}).get("Code") != "AccessDenied":
                raise

    return WhoamiInfo(**data)


if __name__ == "__main__":
    main()
