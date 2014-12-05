# Quickstack init
class quickstack (
) inherits quickstack::params {

  $list = scenario_classes("$scenario", $scenarii)
  $incl = join($list)
  notify {"running $scenario":}
  notify {"$list":}
  # $list.each |$e| { include "$e" }
  include $incl
}
