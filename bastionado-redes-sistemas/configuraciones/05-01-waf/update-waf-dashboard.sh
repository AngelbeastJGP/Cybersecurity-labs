#!/bin/bash

set -eu

ACCESS_LOG=/var/log/httpd/access_log
INCIDENT_LOG=/tmp/waf-incidents.log
REPORT=/var/www/html/waf-incidents.html

awk '$9 == 403' "$ACCESS_LOG" > "$INCIDENT_LOG"

/usr/bin/goaccess "$INCIDENT_LOG" \
  --log-format=COMBINED \
  --html-report-title="Incidencias WAF - SRV-ALMA" \
  --output="$REPORT"

/usr/sbin/restorecon "$REPORT"
