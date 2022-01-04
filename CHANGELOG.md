# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## [3.0.0]
### Changed
- Changes to setup script:
  * Now uses a menu
  * Should be run as the user that will run the backup
  * Puts config files in $HOME/.borgbackup
  * Creates repo with the 'borg init' command if a new backup job is setup

### Added
- Support for pre/post-backup hooks in borgbackup-job (see template files)
- Mandatory parameter `envfile` reads backup job configuration from file
- Support for arguments and the following is now implemented:
  * `--excludes` which excludes given paths from backup
  * `--dry-run` which runs sort of a dry run with given arguments
  * `--help` which prints help section

## [2.0.0]
### Changed
- Setup script now installs the job in `/usr/local/bin` instead of `/usr/bin`

[3.0.0]: https://github.com/ehannes/borgbackup-job/compare/v2.0.0...v3.0.0
[2.0.0]: https://github.com/ehannes/borgbackup-job/compare/v1.0.0...v2.0.0
