# borgbackup-job
A generic job for backing up your data with [Borg](https://borgbackup.readthedocs.io/en/stable/).

This generic script runs the actual borg commands to create a backup.
It is intended to be used from other scripts which provides the paths to backup.
Often, you also need to do other things when creating a backup,
like stopping serices and such.

In borg, you can divide your backups into repositories. You can for instance have one
backup per machine, or one backup per service. That's up to you. This script provides the
shared parts for these backup scripts. You need to provide the actual paths to backup
to this script.

My setup looks something like this:

```
             Service A               Service B
                   \                   /
  Cron job for Service A           Cron job for Service B
                     \               /
      Service A backup job       Service B backup job
                       \          /
                      borgbackup-job
```

## Getting started
Start with installing borg itself. If you are using `apt`, simple run `# apt install borgbackup`.

### setup.sh
This script helps you setup borgbackup-job. It has a generic part and a part for configuring a remote host.
Please review it first since it might do stuff that you don't want.
If you want to configure it differently, just pick the pieces that fits your setup.

Prerequisites:
- Read the [borg documentation](https://borgbackup.readthedocs.io/en/stable/index.html). It's important that you understand how it works since it's your backup solution.
- Read about how to [initialize a borg repository](https://borgbackup.readthedocs.io/en/stable/usage/init.html).
- Borg installed on the client host, the machine to backup
- Clone this repo to the client host so you have the script available there
- A user on the client machine that has read access to the files you want to backup

To be able to call `borgbackup-job` from another script, it's convinient to place the script in system PATH. The script will help you do that.

#### Configure a remote host
The setup script can help you setup a remote host.

You need to have borg installed on the client machine. You should also install borg on the remote if you can, since this will speed up the backup process.

To reach the remote host, SSH is used. Therefore, you will need to create a "backup user" on the remote host that will "receive" the files. This user should be locked down and not used for anything else than creating backups. It obviously needs write access to the directory where you will place your backups.

Prerequisites:
- Pick a remote host with an SSH server.
- A backup user on the remote host.
- It is not required, but recommended, to install borg on the remote host
- A directory to place the backups in, something like `/srv/backups`.

Initialize a borg repository on the remote, see [borg documentation](https://borgbackup.readthedocs.io/en/stable/index.html) for more examples:
```
$ borg init --encryption=repokey-blake2 ssh://backup-user-on-remote-host@remote-host:ssh-port-number/path-to-backup-directory/borg-repository-name
```
To automate things, the script will also help you setup:
- Authentication to remote host with SSH keys
- Create a passphrase file for the repository encryption key

The user on the client machine that runs the backup job obviously needs access to all files to backup. Since that's the case, it shouldn't be a problem security wise to place the encryption key to the repository in that user's home directory, if the permissions are locked down properly. The script will help you setup such a passphrase file.

### Environment variables
The following two are required: `BORG_REPO`, `BORG_PASSPHRASE`.

### Arguments
The script takes one argument, which can be many: a list of space separated paths that should be backed up. Like this:

```
$ borgbackup-job /path/to/dir1 /path/to/dir2
```

### Updating
Update the source code and checkout the newest tag release:
```
git fetch origin
git tag
git checkout vX.Y.Z
```
