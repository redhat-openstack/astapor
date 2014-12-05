# Common quickstack configurations
class quickstack::run (
  $scenario = undef,
) inherits quickstack::params {

  notify {"test $scenario":}

}
