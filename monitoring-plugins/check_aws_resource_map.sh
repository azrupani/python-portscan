#!/bin/bash

#
# This script is aimed at inspecting the syseng_scan database which is updated daily by 2 scripts:
# - aws_public_resource_audit.py [Keeps an uptodate directory of our public resources in aws route53, ec2 and elb]
# - aws_nmap_scan.py [runs a daily scan against the resources found by the previous script and stores result in a db]
# What we will be alerting on is:
# - If any unacknowledged or not (newly acknowledged) records are present in the db (ack-check)
# - If records present in the db were last seen more than 2 days ago (stale-check)
#

DB_HOST="<ADDME>"
DB_USER="<ADDME>"
DB_PASS='<ADDME>'
DB_NAME="syseng_scan"
DB_TABLE_NAME="scan_target"

function sendMonitoring {
        echo "${1}"
        exit ${2}
}

function usage {
        echo "Format: ${0} -t <ack-check|stale-check>"
        echo "Example: ${0} -t ack-check"
        exit 1
}


while getopts "t:" opt
do
	case ${opt} in
		t)
			CHECK_TYPE=${OPTARG}
		;;
	esac
done

if [[ -z ${CHECK_TYPE} ]]
then
	usage
fi

if [[ ${CHECK_TYPE} != "ack-check" && ${CHECK_TYPE} != "stale-check" ]]
then
	usage
fi

case ${CHECK_TYPE} in
        "ack-check")
                MYSQL_QUERY="SELECT count(*) FROM scan_results WHERE ((DateAccepted < date_sub(now(), interval 6 month) OR (DateAccepted IS NULL)) AND MonitoringEnabled = 1);"
		ICINGA_MSG_PREFIX="entries haven't been acknowledged in last 6 months"
        ;;

        "stale-check")
                MYSQL_QUERY="SELECT count(*) FROM scan_results WHERE ((DateLastFound < date_sub(now(), interval 2 day)) AND MonitoringEnabled = 1);"
		ICINGA_MSG_PREFIX="entries have been stale since last 2 days"
        ;;
esac

#
# Execute the check
#

ANAMOLIES_COUNT=$(mysql -N -B -u ${DB_USER} -p${DB_PASS} -h ${DB_HOST} ${DB_NAME} --execute "${MYSQL_QUERY}")

if ! [[ ${ANAMOLIES_COUNT} =~ ^[0-9]+$ ]]
then
        ICINGA_MSG="Alert: Unexpected or Invalid result recieved from the database"
        sendMonitoring "${ICINGA_MSG}" ${ICINGA_EXIT}
fi

if [[ ${ANAMOLIES_COUNT} > 0 ]]
then
        ICINGA_EXIT=1
	ICINGA_MSG="WARNING: ${ANAMOLIES_COUNT} ${ICINGA_MSG_PREFIX}"
        sendMonitoring "${ICINGA_MSG}" ${ICINGA_EXIT}
elif [[ ${ANAMOLIES_COUNT} -eq 0 ]]
then
	ICINGA_EXIT=0
        ICINGA_MSG="OK: No anomalies were detected in the syseng_scan database."
        sendMonitoring  "${ICINGA_MSG}" ${ICINGA_EXIT}
else
        ICINGA_MSG="UNKNOWN: Shouldn't have got here - run script in debug mode and investigate"
        sendMonitoring ${ICINGA_MSG} 3
fi

