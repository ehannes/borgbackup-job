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

### Environment variables
The following two are required: `BORG_REPO`, `BORG_PASSPHRASE`.

### Arguments
The script takes one argument, which can be many: a list of space separated paths that should be backed up. Like this:

```
$ borgbackup-job /path/to/dir1 /path/to/dir2
```
