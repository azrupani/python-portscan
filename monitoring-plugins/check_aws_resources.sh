#!/bin/bash

#
# We have aws_public_resource_audit.py running on syds1syseng01 which polls AWS resources every half hour and stores data on when a particular entry was found and/or when an entry was successfully verified. This check will be checking for:
#
# Alarm if a new entry was found in the last 72 Hours (Warning)
# Alarm if an existing entry was not confirmed in the last 1 hour (Critical)
#

#
# MySQL Variables
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
	echo "Format: ${0} -t \"check-new-resource|check-missing-resource\" [-n <new-resource-time-threshold-in-hours> -m <missing-resource-time-threshold-in-hours>]"
	echo "Example: ${0} -t check-new-resource -n 72"
	echo "Note: -n and -m cannot be defined at the same time. -n can only be used with check-new-resource and -m can only be used withi check-missing-resource"
	exit 1
}

while getopts "t:n:m:" opt
do
	case ${opt} in
		t)
			CHECK_TYPE=${OPTARG}
		;;
		n)
			NEW_RESOURCE_ALARM_THRESHOLD=${OPTARG}
		;;
		m)
			MISSING_RESOURCE_ALARM_THRESHOLD=${OPTARG}
		;;
	esac
done

if [[ ${CHECK_TYPE} != "check-new-resource" && ${CHECK_TYPE} != "check-missing-resource" ]]
then 
	usage
elif [[ -n ${NEW_RESOURCE_ALARM_THRESHOLD} && -n ${MISSING_RESOURCE_ALARM_THRESHOLD} ]]
then
	usage
fi

#
# Set defaults, if in case they are not passed as parameters
#

if [[ ${CHECK_TYPE} == "check-new-resource" ]]
then
	HOURLY_THRESHOLD=${NEW_RESOURCE_ALARM_THRESHOLD:-72}
	ICINGA_EXIT=1
	PROBLEM_MSG="Alert: \${ANAMOLIES_COUNT} new resources were found in last ${HOURLY_THRESHOLD} hours. Check: https://portscan.assetowl.ninja/list-resources.php"
elif [[ ${CHECK_TYPE} == "check-missing-resource" ]]
then
	HOURLY_THRESHOLD=${MISSING_RESOURCE_ALARM_THRESHOLD:-1}	
	ICINGA_EXIT=2
	PROBLEM_MSG="Alert: \${ANAMOLIES_COUNT} resources were NOT found in last ${HOURLY_THRESHOLD} hours. Check: https://portscan.assetowl.ninja/list-resources.php"
fi

#
# Now that validation is done and variables are set, we will execute the SQL to check for any descrepancies based on the check type:
#

case ${CHECK_TYPE} in
	"check-new-resource")
		MYSQL_QUERY="SELECT count(*) FROM ${DB_TABLE_NAME} WHERE ((EntryCreationTime > date_sub(now(), interval ${HOURLY_THRESHOLD} hour)) AND MonitoringEnabled = 1);"
	;;
	
	"check-missing-resource")
		MYSQL_QUERY="SELECT count(*) FROM ${DB_TABLE_NAME} WHERE ((LastSuccessfulCheck < date_sub(now(), interval ${HOURLY_THRESHOLD} hour)) AND MonitoringEnabled = 1);"
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
	ICINGA_MSG=$(eval echo "${PROBLEM_MSG}")
	sendMonitoring "${ICINGA_MSG}" ${ICINGA_EXIT}
elif [[ ${ANAMOLIES_COUNT} -eq 0 ]]
then
	ICINGA_MSG="OK: No anomalies were discovered when checking for last ${HOURLY_THRESHOLD} hours"
	ICINGA_EXIT=0
	sendMonitoring  "${ICINGA_MSG}" ${ICINGA_EXIT}
else
	ICINGA_MSG="UNKNOWN: Shouldn't have got here - run script in debug mode and investigate"
	sendMonitoring ${ICINGA_MSG} 3
fi

