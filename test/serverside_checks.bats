# shellcheck disable=SC1090 # ("Can't follow non-constant source")
# shellcheck disable=SC2154 # ("variable referenced but not assigned") Using variables assigned in sourced script

load serverside_common.bash

### tests

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
