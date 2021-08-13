#!/bin/bash
#example script for running backup from cron, for example:
# /etc/cron.d/borgbackup:
##
## cron.d for borgbackup
##
#PATH=/usr/local/bin/:/usr/bin:/bin
#30 03 * * * root /usr/local/bin/job.template.bash

set -o errexit
TO_BACKUP=(
  "/home/test/a-directory-to-backup"
  "/srv/test/another directory to backup"
  )

#get repo name and auth details
source $HOME/.borg-reponame-env.bash

function stop_services {
  echo 'Stopping services that can alter data'
  # TODO: stop services
}

function start_services_again {
  echo 'Starting services again'
  # TODO: start servies
}
echo 'Starting borg backup job'

stop_services

# Ensure services are always started again, even on early exit
trap start_services_again EXIT

borgbackup-job "${TO_BACKUP[@]}"
