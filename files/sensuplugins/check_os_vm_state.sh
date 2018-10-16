#!/bin/bash

# Arguments:
#
# -p Password for admin user in admin project
# -u URL to keystone v3 public API

while getopts "p:u:s:" opts; do
  case $opts in
    p) password=$OPTARG ;;
    u) url=$OPTARG ;;
    s) status=$OPTARG ;;
  esac
done

export OS_USER_DOMAIN_NAME="Default"
export OS_PROJECT_NAME="admin"
export OS_USERNAME="admin"
export OS_PASSWORD=$password
export OS_AUTH_URL=$url
export OS_IDENTITY_API_VERSION=3

projectid=$(openstack project show $OS_PROJECT_NAME -f value -c id 2> /dev/null)
if [ $? -ne 0 ]; then
  echo "UNKNOWN - No response from API, or invalid credentials"
  exit $UNKNOWN
fi
export OS_PROJECT_ID=$projectid

OK=0
WARNING=1
CRITICAL=2
UNKNOWN=3

ids=()

vms=$(openstack server list -f value -c ID --all-projects --status "${status}" 2> /dev/null)

if [ $? -ne 0 ]; then
  echo "UNKNOWN - No response from API, or invalid credentials"
  exit $UNKNOWN
fi

if [ ! -z "${vms}" ]; then
  for id in ${vms}; do
    now=$(date +%s)
    created=$(openstack server show "${id}" -f value -c created | xargs date +%s -d)
    diff=$((now - created))
    if [ $diff -ge 300 ]; then
      ids=(${ids[@]} $id)
    fi
  done
  if [ ! ${#ids[@]} -eq 0 ]; then
    msg="CRITICAL"
    exitcode=$CRITICAL
  fi
else
  msg="OK"
  exitcode=$OK
fi

if [ $exitcode -eq $OK ]; then
  echo "$msg - No instances is stuck in status $status"
elif [ $exitcode -eq $CRITICAL ]; then
  echo -e "$msg - The following instances has been stuck in status $status for >5 minutes:\n$(printf '%s\n' "${ids[@]}")"
fi

exit $exitcode
