# shellcheck disable=SC1090 # ("Can't follow non-constant source")
# shellcheck disable=SC2154 # ("variable referenced but not assigned") Using variables assigned in sourced script

load serverside_common.bash

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
  declare_globals
  mock_df 111G

  run check_disk_space
  assert_no_mocks_called
  assert_output --regexp "diskcheckGB not set.*OK"

  conf_diskcheck["dummy"]=110
  run check_disk_space
  assert_output -p OK
  refute_output -p FAIL

  conf_diskcheck[dummy]=110
  conf_diskcheck[dummy2]=110
  run check_disk_space
  assert_output -p OK
  refute_output -p FAIL

  conf_diskcheck[bigenough]=110
  # shellcheck disable=SC2034 # "appears unused"
  conf_diskcheck[requirelots]=512
  run check_disk_space
  assert_output --regexp requirelots.*FAIL
  assert_output --regexp bigenough.*OK
}

function e2e_success() { #@test
  mock_externals
  source "$script_to_test"

  run main --hcslug batstestcase --hcpingkey a1 --address example.com --diskcheckGB 100:/tmp

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
