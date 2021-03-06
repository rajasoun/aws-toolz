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
import traceback
import json
import logging
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


def parse_args():
    """Parse Command Line Args"""
    parser = argparse.ArgumentParser(description=DESCRIPTION)
    parser.add_argument("--profile", help="AWS profile to use")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    parser.add_argument("--version", action="store_true")
    parser.add_argument("--debug", action="store_true")
    args = parser.parse_args()
    return args, parser


def format_whoami(whoami_infomation):
    """Format whoami info"""
    lines = [("Account: ", whoami_infomation.Account)]
    for alias in whoami_infomation.AccountAliases:
        lines.append(("", alias))
    lines.append(("Region: ", whoami_infomation.Region))
    if whoami_infomation.SSOPermissionSet:
        lines.append(("AWS SSO: ", whoami_infomation.SSOPermissionSet))
    else:
        type_str = "".join(
            p[0].upper() + p[1:] for p in whoami_infomation.Type.split("-")
        )
        whoami_line = "{}: "
        lines.append((whoami_line.format(type_str), whoami_infomation.Name))
    if whoami_infomation.RoleSessionName:
        lines.append(("RoleSessionName: ", whoami_infomation.RoleSessionName))
    lines.append(("UserId: ", whoami_infomation.UserId))
    lines.append(("Arn: ", whoami_infomation.Arn))
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
    elif hasattr(session, "_session"):  # allow boto3 Session as well
        # pylint: disable=protected-access
        session = session._session

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
        except IndexError as error:
            data["SSOPermissionSet"] = None
            logging.critical(error)
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


def handle_error(args, error):
    """Handel Error"""
    if args.debug:
        traceback.print_exc()
    err_cls = type(error)
    err_cls_str = err_cls.__name__
    if err_cls.__module__ != "builtins":
        format_msg = "{}.{}"
        err_cls_str = format_msg.format(err_cls.__module__, err_cls_str)
    msg = "ERROR [{}]: {}\n"
    sys.stderr.write(msg.format(err_cls_str, error))
    sys.exit(1)


def main():
    """Entry Point"""
    args, parser = parse_args()

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
        info = whoami(session=session, disable_account_alias=disable_account_alias)

        if args.json:
            print(json.dumps(info._asdict()))
        else:
            print(format_whoami(info))
    except botocore.exceptions.NoCredentialsError as error:
        handle_error(args, error)


if __name__ == "__main__":
    main()
