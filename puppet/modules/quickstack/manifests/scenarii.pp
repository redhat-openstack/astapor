# Quickstack scenarii
class quickstack::scenarii (
) inherits quickstack::params {
  $scenarii.each |$e| {
    notify {"Scenario => $e":}
  }
}
