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

  $spc = "Scenario's Puppet classes: ${modules}"
  notify {"$spc":}
  #notify {"Scenario's Puppet classes: ${modules}":}

  #notify {"$modules":}
}
