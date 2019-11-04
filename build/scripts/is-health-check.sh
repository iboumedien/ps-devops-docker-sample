#!/bin/sh
## This script is used a health check on Integration Server running in a docker container then run custom scripts post startup.

############# Function run post startup ##############
run_post_startup() {

  if [ -f "${base_directory}/is-auto-deploy.sh" ] ; then
    sh "${base_directory}/is-auto-deploy.sh"
  fi
  echo "Finished running post statrup scripts..."
  
}

############# Function main ##############
main() {

base_directory=$(dirname "$0")

if [ -z "$IS_PORT" ]; then
    IS_PORT="5555"
fi

status=`curl -s -o /dev/null -w "%{http_code}" localhost:$IS_PORT/invoke/wm.server/ping`

cmdret=$?
if [[ $cmdret != 0 || "$status" != "200" ]]
then
	  echo "Failed to connect to server..."
  exit 1
else
	if [ ! -e /tmp/is_healthy.log ]
	then
		touch /tmp/is_healthy.log
		run_post_startup
	fi

  exit 0
fi

}

main $*
