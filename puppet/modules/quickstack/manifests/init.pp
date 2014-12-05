# Quickstack init
class quickstack (
  $scenario = undef,
) inherits quickstack::params {

  notify {"running $scenario":}
  # notify {"test $scenarii":}

  $list = scenario_classes($scenario, $scenarii)
  notify {$list:}
  include $list
}
