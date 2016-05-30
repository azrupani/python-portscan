#!/usr/bin/python
# Requires the following two rpm: python-dns, MySQL-python
# Requires the following pip: python-nmap [pip install python-nmap]

import nmap
import MySQLdb
import time
import logging
import os
import re
import dns.resolver

log_dir = "/var/log/aws-nmap-scan/"
log_file_name = "scan_" + time.strftime("%d-%m-%Y") + ".log"

if not os.path.exists(log_dir):
  os.makedirs(log_dir)

if os.path.exists(log_dir + log_file_name):
  os.remove(log_dir + log_file_name)

logging.basicConfig(filename="%s%s" % (log_dir, log_file_name), level=logging.DEBUG)
logging.info('Nmap Scan started for AWS resources')

port_range_to_check = '1-1024'

conn = MySQLdb.connect(host="<CHANGEME>",
  user="<CHANGEME>",
  passwd='<CHANGEME>',
  db="<CHANGEME>")

x = conn.cursor()

def sqlAddOrUpdateOpenPort(resourceid, port, protocol):
  try:
    x.execute("INSERT INTO scan_results(ResourceId, OpenPort, Protocol, DateFirstFound, DateLastFound) VALUES (%s, %s, %s, NOW(), NOW())", (resourceid, port, protocol))
    conn.commit()
    logging.info("Success: New Resource-Port map added to the DB")
  except MySQLdb.IntegrityError:
    x.execute("UPDATE scan_results set DateLastFound = NOW() WHERE ResourceId = %s", (resourceid))
    conn.commit()
    logging.info("Success: DateLastFound attribute of the existing record updated in the DB")
  except:
    logging.info("ERROR: Failed to INSERT or UPDATE record in the scan_results table")
    print(x._last_executed)
    raise
    conn.rollback()
#
# Find the Target against which the scan needs to run:
#

regex = re.compile('.*\.sample\.domain\.')
my_resolver = dns.resolver.Resolver()
my_resolver.nameservers = ['8.8.8.8']

fetch_target_query = "SELECT Id, Target FROM scan_target"
try:
  x.execute(fetch_target_query)
  result_count = x.rowcount
  logging.info("%d public resources will be scanned" % (result_count))
  rows = x.fetchall()
  for row in rows:
    resourceid = row[0]
    target = row[1]
    # For targets ending in sample.domain. check the external DNS server for the resource to check:
    matchfound = regex.match(target)
    if matchfound:
      answer = my_resolver.query("%s" % (target))
      target = answer[0]
    logging.info("\nBeginning TCP and UDP scan for [Resource ID: %d - Target: %s] on port range: %s" % (resourceid, target, port_range_to_check))
    nm = nmap.PortScanner()
    nm.scan("%s" % (target), arguments="-sU -sS -p %s" % (port_range_to_check))
    for scanned_ip in nm.all_hosts():
      for protocol in nm[scanned_ip].all_protocols():
        logging.info("List of %s Open Ports (If Any):" % (protocol))
        for port in nm[scanned_ip][protocol].keys():
          state = nm[scanned_ip][protocol][port]['state']
          if state == "open":
            logging.info("Port %s found, commiting result to DB" % (port))
            #print "Protocol %s - Port %s found open" % (protocol, port)
	    sqlAddOrUpdateOpenPort(resourceid, port, protocol)
  conn.close()
except:
  print(x._last_executed)
  raise
  conn.close()
  logging.info("ERROR: Failed to get a list of resources to check from the scan_results table on syseng_scan database")

