# Common quickstack configurations
class quickstack::run (
) inherits quickstack::params {

  notify {"test $scenario":}

  $foo = scenario_classes($scenario)

  notify {"test $foo":}

  if  $foo.empty {
    notify {"No classes to run":}
  }
  else {
    hiera_include($foo)
  }
}
