# Quickstack scenarii
class quickstack::scene (
) inherits quickstack::params {

  $modules = scenario_classes("$scenario", $scenarii)

  notify {"quickstack::scene: Available Scenarios":}
  ->
  notify {"$scenarii":}

  notify {"quickstack::params::scenario":}
  ->
  notify {"$scenario":}

  notify {"Scenario's Puppet classes":}
  ->
  notify {"$modules":}
}
