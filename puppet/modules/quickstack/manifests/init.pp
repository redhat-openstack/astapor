# Quickstack init
class quickstack (
) inherits quickstack::params {

  $list = join(scenario_classes("$scenario", $scenarii))
  notify {"running $scenario":}
  notify {"$list":}
  # $list.each |$e| { include "$e" }
  include $list
}
