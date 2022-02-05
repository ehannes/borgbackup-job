# shellcheck disable=SC1090 # ("Can't follow non-constant source")
# shellcheck disable=SC2154 # ("variable referenced but not assigned") Using variables assigned in sourced script

setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  load 'test_helper/bats-mock/load'
  load 'test_helper/bats-file/load'

  PROJECT_ROOT="$( cd "$( dirname "$BATS_TEST_FILENAME")"  >/dev/null 2>&1 && pwd)/.."
  PATH="$PROJECT_ROOT:$PATH"

  script_to_test=borg_serverside_checks
}

function teardown() {
  if [[ $tmpdir ]]; then
    temp_del "$tmpdir"
  fi
}

### mocks

function mock_curl() {
  mocked_curl="$(mock_create)"
  function curl() {
    $mocked_curl "$@"
  }
  export -f curl
  export mocked_curl
}
function mock_host() {
  mocked_host="$(mock_create)"
  mock_set_output "$mocked_host" "host.example.com has address 11.11.11.11"
  function host() {
    $mocked_host "$@"
  }
  export -f host
  export mocked_host
}
function mock_host_failure() {
  # failure return for host
  mocked_host_fail="$(mock_create)"
  mock_set_output "mocked_host_fail" "Host $(mock_get_call_args "$mocked_host_fail") not found: 2(SERVFAIL)"
  function host() {
    $mocked_host "$@"
  }
  export -f host
  export mocked_host_fail
}
function mock_host_with_failure_then_success() {
  mocked_host_fail="$(mock_create)"
  mock_set_output "$mocked_host_fail" "Host $(mock_get_call_args "$mocked_host_fail") not found: 2(SERVFAIL)" 1
  mock_set_status "$mocked_host_fail" 1 1
  mock_set_output "$mocked_host_fail" "$(mock_get_call_args "$mocked_host_fail") has address 11.11.11.11" 2
  mock_set_status "$mocked_host_fail" 0 2
  function host() {
    $mocked_host_fail "$@"
  }
  export -f host
  export mocked_host_fail
}

function mock_df() {
  local size=$1
  mocked_df="$(mock_create)"
  mock_set_output "$mocked_df" " ${size:-111G}"
  function df() {
    $mocked_df "$@"
  }
  export -f df
  export mocked_df
}

function mock_externals() {
  mock_curl
  mock_host
  mock_df
}

function assert_no_mocks_called() {
  for the_mock in mocked_df mocked_host mocked_host_failed mocked_curl; do
    if [[ ${!the_mock} ]]; then
      assert_equal ${the_mock}_called_"$(mock_get_call_num "${!the_mock}")"_times \
        ${the_mock}_called_0_times
    fi
  done
}

### tests

ipv4regexp='^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}$'

function can_run() { #@testignore
  run borg_serverside_checks
  assert_failure 2 # exits with 1 for now

  source "$script_to_test"

  run main
  assert_failure 2
  assert_output -p "stdout"
  assert_output -p "stderr"
}

function args_missing_address_exits_with_help() { #@test
  source "$script_to_test"
  run init -a
  assert_failure 2
  assert_output --partial Usage
}

function get_public_ip_returns_an_ipv4_address() { #@test
  source "$script_to_test"
  #  mock_host # DON'T mock this. Would only test that the mock returns a valid address. Useless!

  local ret
  get_public_ip
  # shellcheck disable=SC2034 # "variable appears unused". (assert_output uses it)
  output="$ret"
  assert_output --regexp "$ipv4regexp"
}

function get_public_ip_failure_generates_failure() { #@test
  source "$script_to_test"
  mock_host_with_failure_then_success

  run get_public_ip  # this runs in subshell to catch output
  assert_output -p "FAIL"
  assert_output -p "get external (internet) ip address."
}

function get_dns_ip_returns_an_ipv4_address() { #@test
  source "$script_to_test"
  mock_host

  run   get_dns_ip example.com
  assert_output -p OK
  get_dns_ip example.com
  output=$ret
  assert_output --regexp "$ipv4regexp"
}

function get_dns_ip_reports_failure_correctly() { #@test
  source "$script_to_test"
  mock_host_failure

  run get_dns_ip example.com
  assert_output -p FAIL
  get_dns_ip example.com
  output=$ret
  refute_output --regexp "$ipv4regexp"

}

function verify_ips_are_same_fails_correctly() { #@test
  source "$script_to_test"

  run verify_ips_are_same 1 2
  assert_output -p FAIL

  run verify_ips_are_same 1
  assert_output -p FAIL
}

function verify_ips_are_same_succeeds() { #@test
  source "$script_to_test"

  run verify_ips_are_same 1.2.3.4 1.2.3.4
  assert_output -p OK
  refute_output -p FAIL
}

function check_diskspace_gb_test() { #@test
  source "$script_to_test"
  mock_df 111G

  # check that default limit is used
  run check_disk_space /dummy
  assert_output -p OK
  refute_output -p FAIL

  # shellcheck disable=SC2034 # "appears unused"
  conf["minsize"]=112
  run check_disk_space /dummy
  assert_output -p FAIL
  refute_output -p OK
}

function healthcheck_report_doesnt_call_curl_when_no_env_set() { #@test
  source "$script_to_test"
  mock_curl

  unset HEALTHCHECKS_PINGKEY
  unset HEALTHCHECKS_SLUG
  healthcheck_report start
  assert_equal "$(mock_get_call_num "${mocked_curl}")" 0

  HEALTHCHECKS_PINGKEY=123
  healthcheck_report start
  assert_equal "$(mock_get_call_num "${mocked_curl}")" 0

  unset HEALTHCHECKS_PINGKEY
  HEALTHCHECKS_SLUG=batstestcase
  healthcheck_report start
  assert_equal "$(mock_get_call_num "${mocked_curl}")" 0
}

function healthcheck_report_calls_curl() { #@test
  source "$script_to_test"
  mock_curl

  # shellcheck disable=SC2034
  HEALTHCHECKS_PINGKEY=123 HEALTHCHECKS_SLUG=batstestcase
  healthcheck_report start
  assert_equal "$(mock_get_call_num "${mocked_curl}")" 1
  [[ $(mock_get_call_args "${mocked_curl}") =~ hc-ping.*/start ]]
}

function failures_causes_summary_logging_and_healthcheck_fail_report() { #@test
  source "$script_to_test"
  mock_curl

  run register_result "$fail" bats testing of failure # this runs in subshell to catch output
  assert_output -p "FAIL"
  assert_output -p "bats testing of failure"

  HEALTHCHECKS_PINGKEY=123 HEALTHCHECKS_SLUG=batstestcase
  register_result "$fail" bats testing of failure  # run in this shell, to update global variables
  run evaluate_and_report_healthckecksio
  assert_output -p "Summary"
  assert_output -p "bats testing of failure"
  [[ $(mock_get_call_args "${mocked_curl}") =~ hc-ping.*$HEALTHCHECKS_SLUG/fail$ ]]
}

function success_causes_summary_logging_and_healthcheck_success_report() { #@test
  source "$script_to_test"
  mock_curl

  run register_result "$ok" bats testing of success # this runs in subshell to catch output
  assert_output -p "OK"
  assert_output -p "bats testing of success"

  # shellcheck disable=SC2034 # "variable appears unused"
  HEALTHCHECKS_PINGKEY=123 HEALTHCHECKS_SLUG=batstestcase
  register_result "$ok" bats testing of success  # run in this shell, to update global variables
  run evaluate_and_report_healthckecksio
  assert_output -p "Summary"
  assert_output -p "bats testing of success"
  [[ $(mock_get_call_args "${mocked_curl}") =~ hc-ping.*$HEALTHCHECKS_SLUG$ ]]
}

function parameter_parsing() { #@test
  source "$script_to_test"
  declare_globals

  parse_params --address example.com --conf /dev/null --hcpingkey a1 --hcslug slug --diskpath /srv --min_sizeGB 42
  assert_equal "${conf[address]}" "example.com"
  assert_equal "${conf[conffile]}" "/dev/null"
  assert_equal "${conf[hcpingkey]}" "a1"
  assert_equal "${conf[hcslug]}" "slug"
  assert_equal "${conf[diskpath]}" "/srv"
  assert_equal "${conf[min_sizeGB]}" "42"

  run parse_params -h
  assert_output -p "Usage"
  assert_success

  run parse_params -a example.com rubbish
  assert_output -p "unknown parameter: rubbish"
  assert_output -p "Usage"
  assert_failure

  for p in address conf hcpingkey hcslug diskpath min_sizeGB; do
    run parse_params --$p --bazinga
    assert_output --regexp "$p requires.*argument"
    assert_failure
  done
}

function missing_required_parameters() { #@test
  mock_externals

  run $script_to_test
  assert_no_mocks_called
  assert_output -p Usage
  assert_failure

  run $script_to_test --address example.com
  assert_no_mocks_called
  assert_output -p diskpath
  assert_output -p Usage
  assert_failure

  run $script_to_test --diskpath /tmp
  assert_no_mocks_called
  assert_output -p address
  assert_output -p Usage
  assert_failure
}

function cmdline_options_override_configfile_allparams() { #@test
  tmpdir=$(temp_make)
  conffile=$tmpdir/batstest.conf
  cat <<EOF  | sed 's/^\s*//' > "$conffile"
  # This is a comment and next line is empty

  address=fromfile.example.com
  hcpingkey=lisa
  hcslug=sluggo
  min_sizeGB=13
  diskpath=$tmpdir
EOF
  mock_externals
  source "$script_to_test"
  declare_globals

  main --address example.com --conf "$conffile" --hcpingkey a1 --hcslug slug --diskpath /srv --min_sizeGB 42

  assert_equal "${conf[address]}" "example.com"
  assert_equal "${conf[conffile]}" "$conffile"
  assert_equal "${conf[hcpingkey]}" "a1"
  assert_equal "${conf[hcslug]}" "slug"
  assert_equal "${conf[diskpath]}" "/srv"
  assert_equal "${conf[min_sizeGB]}" "42"
}

function cmdline_options_and_configfile_mixed() { #@test
  tmpdir=$(temp_make)
  conffile=$tmpdir/batstest.conf
  cat <<EOF  | sed 's/^\s*//' > "$conffile"
  address=fromfile.example.com
  hcpingkey=lisa
  hcslug=sluggo
EOF
  mock_externals
  source "$script_to_test"
  declare_globals

  main --conf "$conffile" --diskpath /srv --min_sizeGB 42

  assert_equal "${conf[address]}" "fromfile.example.com"
  assert_equal "${conf[conffile]}" "$conffile"
  assert_equal "${conf[hcpingkey]}" "lisa"
  assert_equal "${conf[hcslug]}" "sluggo"
  assert_equal "${conf[diskpath]}" "/srv"
  assert_equal "${conf[min_sizeGB]}" "42"
}

function e2e_success() { #@test
  mock_externals
  source "$script_to_test"

  run main --hcslug batstestcase --hcpingkey a1 --address example.com --diskpath /tmp

  assert_output -p "$ok"
  refute_output -p "$fail"
  assert_equal "$(mock_get_call_num "$mocked_host")" 2
  assert_equal "$(mock_get_call_num "$mocked_df")" 2
  assert_equal "$(mock_get_call_num "${mocked_curl}")" 2
  assert_output -p Summary
  for i in $(seq "$(mock_get_call_num "$mocked_curl")"); do
    output=$(mock_get_call_args "$mocked_curl" "$i")
    refute_output -p /fail
    [[ $output =~ start ]] && hcping_start=hcping_start_was_called
    [[ $output =~ batstestcase$ ]] && hcping_success=hcping_success_found
  done
  assert_equal $hcping_start hcping_start_was_called
  assert_equal $hcping_success hcping_success_found
}

function logging_to_disk() { #@test
  skip "not yet implemented"
}
