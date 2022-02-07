# shellcheck disable=SC1090 # ("Can't follow non-constant source")
# shellcheck disable=SC2154 # ("variable referenced but not assigned") Using variables assigned in sourced script

load serverside_common.bash

### mocks

function mock_curlmock_save_curldata() {
  curlmock="$(mock_create)"
  function check_curl_params() {
      while [[ $1 ]]; do
        [[ $1 == --data-raw ]] && { echo "$2" > $BATS_RUN_TMPDIR/curldata;shift; }
        shift
      done
  }
  mock_set_side_effect "$curlmock" "$(declare -pf check_curl_params)"';check_curl_params "$@"'
  function curl() {
    $curlmock "$@"
  }
  export -f curl
  export curlmock
}

### checks

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

function log_is_included_in_healthcheck_report() { #@test
  mock_curlmock_save_curldata
  source "$script_to_test"
  # shellcheck disable=SC2034 # "variable appears unused"
  HEALTHCHECKS_PINGKEY=123 HEALTHCHECKS_SLUG=batstestcase

  register_result $ok "something worked"
  healthcheck_report success

  assert_equal "$(mock_get_call_num $curlmock)" 1
  # shellcheck disable=SC2034
  output="$(cat $BATS_RUN_TMPDIR/curldata)"
  assert_output -p "something worked"
}