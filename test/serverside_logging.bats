# shellcheck disable=SC1090 # ("Can't follow non-constant source")
# shellcheck disable=SC2154 # ("variable referenced but not assigned") Using variables assigned in sourced script

load serverside_common.bash

function log_of_external_commands_to_disk() { #@test
  # verify that not only internal bash commands (such as mocks) but actual
  # external command output gets redirected to file
  source "$script_to_test"
  declare_globals
  setup_logging
  /bin/echo "hello"
  assert_file_contains "$logfile" hello
}

function logging_to_disk() { #@test
  mock_externals
  source "$script_to_test"
  logfile=$templogdir/$NAME.$(date +%d).log # mimic code in setup_logging
  assert_not_exist "$logfile"  # to make sure the logfile is actually created by the script

  run main --hcslug batstestcase --hcpingkey a1 --address example.com

  # log to stdout works
  assert_output -p "$ok"
  refute_output -p "$fail"
  # log to file also works
  assert_exist "$logfile"
  assert_file_not_empty "$logfile"
  output="$(cat "$logfile")"
  assert_output -p "$ok"
  refute_output -p "$fail"
}

function dont_log_do_disk_if_logdir_is_unset() { #@test
  mock_externals
  source "$script_to_test"
  declare_globals
  assert_not_exist "$logfile"

  unset LOGDIR
  run main --hcslug batstestcase --hcpingkey a1 --address example.com
  assert_output -p "Skipping log file creation, logdir not set"
  assert_not_exist "$logfile"
}

function last_months_log_is_removed() { #@test
  mock_externals
  source "$script_to_test"
  logfile=$templogdir/$NAME.$(date +%d).log # mimic code in setup_logging
  echo "last months data" > "$logfile"
  touch "$logfile" --date 'now -1 month'

  run main --hcslug batstestcase --hcpingkey a1 --address example.com --diskcheckGB 100:/tmp
  # shellcheck disable=SC2034 # "variable appears unused". (assert_output uses it)
  output="$(cat "$logfile")"
  refute_output -p "last months data"
  assert_output -p "$ok"
  refute_output -p "$fail"
}
