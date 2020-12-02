#!/usr/local/bin/python

# See https://pypi.org/project/schedule/
# for the boilerplate of this class.

import schedule
import subprocess
import sys
import time

def job():
    subprocess.call([
        "certbot",
        "renew",
        "--config-dir",
        "/home/certbot/config", # default: /etc/letsencrypt
        "--work-dir",
        "/home/certbot/work", # default: /var/lib/letsencrypt
        "--logs-dir",
        "/home/certbot/logs"], # default: /var/log/letsencrypt
        stdout=sys.stdout,
        stderr=sys.stderr)

# Run the cron every day at midnight and noon.
# https://certbot.eff.org/#pip-other recommends renewing twice a day.
schedule.every().day.at("00:00").do(job)
schedule.every().day.at("12:00").do(job)

while True:
    schedule.run_pending()
    time.sleep(1)
