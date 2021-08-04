#!/bin/bash
#example script for running backup from cron, for example:
# /etc/cron.d/borgbackup:
##
## cron.d for borgbackup
##
#PATH=/usr/local/bin/:/usr/bin:/bin
#30 03 * * * root /usr/local/bin/job.template.bash.sh

set -o errexit
REPOBASE="ssh://user@host:port/path/to/borgbackup"
REPONAME=example-job
TO_BACKUP=(
  "/home/test/a-directory-to-backup"
  "/srv/test/another directory to backup"
  )

export BORG_REPO="$REPOBASE"/"$REPONAME"
export BORG_PASSCOMMAND="cat /root/.borg-passphrase-$REPONAME"

echo 'Starting borg backup job'

echo 'Stopping services that can alter data'
# TODO: stop services

borgbackup-job "${TO_BACKUP[@]}"

echo 'Starting services again'
# TODO: start servies
