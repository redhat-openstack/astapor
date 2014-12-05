# Common quickstack configurations
class quickstack::run (
  $scenario,
) inherits quickstack::params {

  notify {"test $scenario":}

}
