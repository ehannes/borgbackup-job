# Borgbackup job
A job for backing up stuff with borgbackup.
The script is originally from https://borgbackup.readthedocs.io/en/stable/quickstart.html.

## Setup
I have different borg repositories for each service I backup. Therefore, I have one script per service to backup. This script is responsible for setting the correct environment variables. Then, this borgbackup-job script runs the actual borg command for creating and pruning the repository.

To be able to call this script from another script, you can place a symlink to borgbackup-job in /usr/bin, which is one of the available paths when running cron jobs.

So I have this:
```
$ ls -l /usr/bin/borgbackup-job 
... /usr/bin/borgbackup-job -> /usr/local/sbin/borgbackup-job/borgbackup-job
```

### SSH keys
Often, this script will be run by root in a cron job. If you have a remote repository, you often want to authenticate with SSH keys. Remember to do something like
```
# ssh-copy-id user-at-remote@remoteip.com
```
And then, at the `authorized_keys` at `remoteip.com` for user `user-at-remote`, add something like this:
```
command="borg serve --restrict-to-path /path-to-repositories/",restrict
```

### Environment variables
The following two are required: `BORG_REPO`, `BORG_PASSPHRASE`.

### Arguments
The script takes one argument, which can be many: a list of space separated paths that should be backed up. Like this:

```
$ borgbackup-job /path/to/dir1 /path/to/dir2
```
