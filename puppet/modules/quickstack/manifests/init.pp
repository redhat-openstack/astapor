# Quickstack init
class quickstack (
) inherits quickstack::params {

  $list = scenario_classes("$scenario", $scenarii)
  notify {"running $scenario":}
  $list.each |$e| { include "$e" }
}
