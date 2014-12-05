# Common quickstack configurations
class quickstack::run (
) inherits quickstack::params {

  notify {"test $quickstack::params::scenario":}

}
