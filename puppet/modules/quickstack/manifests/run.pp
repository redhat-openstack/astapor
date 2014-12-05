# Common quickstack configurations
class quickstack::run (
) inherits quickstack::params {

  notify {"test $::scenario":}

}
