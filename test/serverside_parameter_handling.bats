# shellcheck disable=SC1090 # ("Can't follow non-constant source")
# shellcheck disable=SC2154 # ("variable referenced but not assigned") Using variables assigned in sourced script

load serverside_common.bash

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

  run "$script_to_test"
  assert_no_mocks_called
  assert_output -p Usage
  assert_failure

  run "$script_to_test" --address example.com
  assert_no_mocks_called
  assert_output -p diskpath
  assert_output -p Usage
  assert_failure

  run "$script_to_test" --diskpath /tmp
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
