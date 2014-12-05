# Common quickstack configurations
class quickstack::run (
) inherits quickstack::params {

  $foo = "$::scenario_classes"
    notify {"test $foo":}
  if  $foo.empty {
    notify {"No classes to run":}
  }
  else {
    hiera_include($foo)
  }
}
