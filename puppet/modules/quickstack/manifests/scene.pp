# Quickstack scenarii
class quickstack::scene (
) inherits quickstack::params {

  $modules = scenario_classes("$scenario", $scenarii)

  notify {"$scenarii":}
  ->
  notify {"$scenario":}
  ->
  notify {"$modules":}
}
