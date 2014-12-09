# Quickstack scenarii
class quickstack::scene (
) inherits quickstack::params {

  $modules = join(scenario_classes("$scenario", $scenarii), ',')
  $scenes = join(any2array($scenarii), ',')

  notify {"quickstack::params::scenarii: ${scenes}":}
  ->
  notify {"quickstack::params::scenario: ${scenario}":}
  ->
  notify {"Scenario's Puppet classes: ${modules}":}
}
