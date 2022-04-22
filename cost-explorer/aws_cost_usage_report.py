#!/usr/bin/env python3

import os

import argparse
import datetime

import boto3.session


def clear_screen():
    import os
    os.system("clear")


def process_cli_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--days', type=int, default=30)
    parser.add_argument('--profile', type=str, default='default')
    args = parser.parse_args()
    now = datetime.datetime.utcnow()
    start = (now - datetime.timedelta(days=args.days)).strftime('%Y-%m-%d')
    end = now.strftime('%Y-%m-%d')
    aws_env = boto3.session.Session(profile_name=args.profile,
                                    aws_access_key_id=os.environ['AWS_ACCESS_KEY_ID'],
                                    aws_secret_access_key=os.environ['AWS_SECRET_ACCESS_KEY'])
    aws_api = aws_env.client('ce', 'us-east-1')
    return aws_api, start, end


def get_cost_usage_from_aws(aws_api, start, end):
    results = []
    token = None
    while True:
        if token:
            kwargs = {'NextPageToken': token}
        else:
            kwargs = {}
        data = aws_api.get_cost_and_usage(
            TimePeriod={'Start': start, 'End': end},
            Granularity='MONTHLY',
            Metrics=['UnblendedCost'],
            GroupBy=[
                {"Type": "DIMENSION", "Key": "LINKED_ACCOUNT"},
                {'Type': 'DIMENSION', 'Key': 'SERVICE'}
            ], **kwargs)
        results += data['ResultsByTime']
        token = data.get('NextPageToken')
        if not token:
            break
    return results


def print_report(results):
    # http://zetcode.com/python/prettytable/
    from prettytable import PrettyTable
    table = PrettyTable()
    table.field_names = ['TimePeriod',
                         'Service', 'Amount', 'Unit', 'Estimated']
    table.align["Service"] = "l"
    table.reversesort = True
    table.sortby = 'Amount'

    total_cost = 0
    for result_by_time in results:
        for group in result_by_time['Groups']:
            service = group['Keys'][1]
            amount = round(
                float(group['Metrics']['UnblendedCost']['Amount']), 2)
            unit = group['Metrics']['UnblendedCost']['Unit']
            if amount > 0.0 and result_by_time['Estimated'] is True:
                table.add_row([result_by_time['TimePeriod']['Start'],
                               service, amount, unit, result_by_time['Estimated']])
                total_cost += float(amount)

    # Clear Screen
    clear_screen()
    budget = table.get_string(title="AWS Budget")
    print(budget)
    print("Total Cost: $ %.2f\n" % round(float(total_cost), 2))


def save_screen_to_image():
    import pyscreenshot as ImageGrab
    #im = ImageGrab.grab()
    # X1,Y1,X2,Y2    # part of the screen
    im = ImageGrab.grab(bbox=(0, 80, 710, 510))
    im.save('./generated/aws_budget.png')
    im.show()


def main():
    aws_client, start, end = process_cli_args()
    results = get_cost_usage_from_aws(aws_client, start, end)
    print_report(results)
    # save_screen_to_image()


main()
