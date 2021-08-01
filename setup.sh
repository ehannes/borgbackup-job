#!/bin/bash

#############
# CONSTRANTS 
#############

BORG_EXECUTE_DIR='/usr/bin/'
JOB_NAME='borgbackup-job'
JOB_PATH="$PWD/$JOB_NAME"

prompt_for_continue () {
  read -p "Continue? [Y/n] " -n 1
  echo # new line
  if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Ok, aborting"
    exit
  fi
}

please_confirm () {
  echo 'Warning: this script should only be run from within the project folder!'
  echo 'Please start with reading the readme.'
  echo 'This script will setup the generic borg backup job.'

  prompt_for_continue
}

place-script-in-path () {
	# sudo ln -s $JOB_PATH $BORG_EXECUTE_DIR
  echo 'test'
}

configure_remote_backup () {
  read -p 'Borg remote host to send backup to (for instance example.com): ' borg_remote_host

	read -p 'Remote user name: ' borg_remote_user
  read -p 'Absolute path to backup directory on remote host (e.g. /srv/backups/): ' borg_remote_backup_path

  echo 'Which user should be used on this machine (the client) for running the backup?'
  echo 'Note that this user needs read access to all files to backup'
  echo 'You can have multiple backup jobs run by different users.'

  read -p 'Client user name: ' client_user_name
  echo "\"$client_user_name\" needs SSH access to the remote host to be able to send over the backups."
  echo 'Please generate an SSH key and copy the id to the remote host.'
  echo "Something like this when logged in as ${client_user_name}:"
  echo '$ ssh-keygen -t rsa -b 4096'
  echo "$ ssh-copy-id ${borg_remote_user}@${borg_remote_host}"
  echo 'Then test the connection with something like:'
  echo "$ ssh ${borg_remote_user}@${borg_remote_host}"
  echo 'Keep in mind to add port number if you are not using standard port 22 for SSH.'

  echo "To lock down this access, we you should append something this to " \
       "/home/${borg_remote_user}/.ssh/authorized_keys\"" \
       "on your remote host \"${borg_remote_host}\":"
  echo "command=\"borg serve --restrict-to-path ${borg_remote_backup_path}\",restrict"
}

setup_job () {
  echo "We can create a password file in ${client_user_name}'s home directory."

  read -p 'Name of the backup job to create: ' job_name
  passphrase_file_path="/home/${client_user_name}/.borg-passphrase-${job_name}"

  read -p "Create ${passphrase_file_path}? [Y/n]"
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    # umask 0377
    # touch $passphrase_file_path
    echo "Add your encryption key to $passphrase_file_path"
  fi

  echo 'Now copy job-template.sh to a suitable place and create your first backup job!'
  echo 'Then create a cron job for scheduling it.'
}

###############
# START SCRIPT
###############

echo "Configuring generic $JOB_NAME"
please_confirm

read -p "Create symlink for ${JOB_NAME} in ${BORG_EXECUTE_DIR}? [Y/n] " -n 1
echo # new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
  place-script-in-path
fi

read -p "Configure remote backup? [Y/n] " -n 1
echo # new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
  configure_remote_backup
fi

read -p "Setup a backup job? [Y/n] " -n 1
echo # new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
  setup_job
fi
