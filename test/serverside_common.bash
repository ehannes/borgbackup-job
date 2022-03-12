setup() {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  load 'test_helper/bats-mock/load'
  load 'test_helper/bats-file/load'

  PROJECT_ROOT="$( cd "$( dirname "$BATS_TEST_FILENAME")"  >/dev/null 2>&1 && pwd)/.."
  PATH="$PROJECT_ROOT:$PATH"

  templogdir="$(temp_make)"
  # shellcheck disable=SC2034 # "appears unused": used in tests
  script_to_test=borg_serverside_checks
  # shellcheck disable=SC2034
  LOGDIR="$templogdir"
}

function teardown() {
  if [[ $tmpdir ]]; then
    temp_del "$tmpdir"
  fi
  temp_del "$templogdir"
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
  mocked_host_fail2="$(mock_create)"
  mock_set_output "mocked_host_fail2" "Host $(mock_get_call_args "$mocked_host_fail2") not found: 2(SERVFAIL)"
  function host() {
    $mocked_host_fail2 "$@"
  }
  export -f host
  export mocked_host_fail2
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

# shellcheck disable=SC2120  # "...references arguments, but none are ever passed.": used in tests
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

# shellcheck disable=SC2034 # "...appears unused.": used in tests
ipv4regexp='^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}$'
