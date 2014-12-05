# Quickstack init
class quickstack (
  $scenario,
) inherits quickstack::params {

  notify {"running $scenario":}
  # notify {"test $scenarii":}

  $list = scenario_classes($scenario, $scenarii)
  notify {$list:}
  include $list
}
