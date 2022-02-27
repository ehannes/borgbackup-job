# shellcheck disable=SC1090 # ("Can't follow non-constant source")
# shellcheck disable=SC2154 # ("variable referenced but not assigned") Using variables assigned in sourced script

load serverside_common.bash

function parameter_parsing() { #@test
  source "$script_to_test"
  declare_globals

  parse_params --address example.com --conf /dev/null --hcpingkey a1 --hcslug slug --diskcheckGB 42:/srv
  #--diskpath /srv --min_sizeGB 42
  assert_equal "${conf[address]}" "example.com"
  assert_equal "${conf[conffile]}" "/dev/null"
  assert_equal "${conf[hcpingkey]}" "a1"
  assert_equal "${conf[hcslug]}" "slug"
  assert_equal "${conf_diskcheck[/srv]}" 42
#  assert_equal "${conf[min_sizeGB]}" "42"

  run parse_params -h
  assert_output -p "Usage"
  assert_success

  run parse_params -a example.com rubbish
  assert_output -p "unknown parameter: rubbish"
  assert_output -p "Usage"
  assert_failure

  for p in address conf hcpingkey hcslug diskcheckGB; do
  #diskpath min_sizeGB; do
    run parse_params --$p --bazinga
    assert_output --regexp "$p requires.*argument"
    assert_failure
  done
}

function args_missing_address_exits_with_help() { #@test
  source "$script_to_test"
  run init -a
  assert_failure 2
  assert_output --partial Usage
}

function missing_required_parameters() { #@test
  mock_externals

  run "$script_to_test"
  assert_no_mocks_called
  assert_output -p Usage
  assert_failure

  run "$script_to_test" --diskpathGB 14:/tmp
  assert_no_mocks_called
  assert_output -p address
  assert_output -p Usage
  assert_failure
}

function read_conf_file() { #@test
  tmpdir=$(temp_make)
  mkdir -p "$tmpdir/target1"
  mkdir -p "$tmpdir/tar get2"
  conffile=$tmpdir/batstest.conf
  cat <<EOF  | sed 's/^\s*//' > "$conffile"
  # This is a comment and next line is empty

  address=example.com
  hcpingkey=cK2UthisisnotyoursZfhg
  hcslug=some-nice-name
  diskcheckGB=(
    100:"$tmpdir/target1"
    50:"$tmpdir/tar get2"
  )
  logdir=/var/log/borgbackup
EOF

  mock_externals
  source "$script_to_test"
  declare_globals

  main --conf $conffile
  assert_equal "${conf[address]}" "example.com"
  assert_equal "${conf[conffile]}" "$conffile"
  assert_equal "${conf[hcpingkey]}" "cK2UthisisnotyoursZfhg"
  assert_equal "${conf[hcslug]}" "some-nice-name"
  assert_equal "${conf_diskcheck["$tmpdir/target1"]}" "100"
  assert_equal "${conf_diskcheck["$tmpdir/tar get2"]}" "50"
}

function cmdline_options_override_configfile_allparams() { #@test
  tmpdir=$(temp_make)
  conffile=$tmpdir/batstest.conf
  cat <<EOF  | sed 's/^\s*//' > "$conffile"
  address=fromfile.example.com
  hcpingkey=lisa
  hcslug=sluggo
  diskcheckGB=(
    13:$tmpdir
  )
EOF
#  min_sizeGB=13
#  diskpath=$tmpdir
  mock_externals
  source "$script_to_test"
  declare_globals

  main --address example.com --conf "$conffile" --hcpingkey a1 --hcslug slug --diskcheckGB 42:/srv
   #--diskpath /srv --min_sizeGB 42

  assert_equal "${conf[address]}" "example.com"
  assert_equal "${conf[conffile]}" "$conffile"
  assert_equal "${conf[hcpingkey]}" "a1"
  assert_equal "${conf[hcslug]}" "slug"
  assert_equal "${conf_diskcheck[/srv]}" "42"
#  assert_equal "${conf[diskpath]}" "/srv"
#  assert_equal "${conf[min_sizeGB]}" "42"
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

  main --conf "$conffile" --diskcheckGB 42:/srv

  assert_equal "${conf[address]}" "fromfile.example.com"
  assert_equal "${conf[conffile]}" "$conffile"
  assert_equal "${conf[hcpingkey]}" "lisa"
  assert_equal "${conf[hcslug]}" "sluggo"
  assert_equal "${conf_diskcheck["/srv"]}" "42"
}
