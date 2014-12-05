# Quickstack init
class quickstack (
) inherits quickstack::params {

  notify {"running $scenario":}
  #notify {"test $scenarii":}

  list = scenario_classes($scenario, $scenarii)
  notify {"showing $list":}
}
