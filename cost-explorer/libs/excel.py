#!/usr/bin/env python3

"""
Cost Explorer Report
"""

from __future__ import print_function

__author__ = "Raja Soundaramourty"
__version__ = "0.1.0"
__license__ = "MIT No Attribution"

import subprocess
import pandas as pd

BASE_DIR = subprocess.Popen(['git', 'rev-parse', '--show-toplevel'],
                            stdout=subprocess.PIPE).communicate()[0].rstrip().decode('utf-8')


class Excel:

    def generate(reports, CURRENT_MONTH=False):
        excel_file = BASE_DIR + "/generated/report.xlsx"
        writer = pd.ExcelWriter(excel_file, engine='xlsxwriter')
        workbook = writer.book
        for report in reports:
            print(report['Name'], report['Type'])
            report['Data'].to_excel(writer, sheet_name=report['Name'])
            worksheet = writer.sheets[report['Name']]
            if report['Type'] == 'chart':
                # Create a chart object.
                chart = workbook.add_chart(
                    {'type': 'column', 'subtype': 'stacked'})
                chartend = 12
                if CURRENT_MONTH:
                    chartend = 13
                for row_num in range(1, len(report['Data']) + 1):
                    chart.add_series({
                        'name':       [report['Name'], row_num, 0],
                        'categories': [report['Name'], 0, 1, 0, chartend],
                        'values':     [report['Name'], row_num, 1, row_num, chartend],
                    })
                chart.set_y_axis({'label_position': 'low'})
                chart.set_x_axis({'label_position': 'low'})
                worksheet.insert_chart(
                    'O2', chart, {'x_scale': 2.0, 'y_scale': 2.0})
        writer.save()
