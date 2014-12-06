# Quickstack scenarii
class quickstack::scenarii (
) inherits quickstack::params {
  notify {"Available scenarios":}
  $scenarii.each |$e| {
    notify {"$e":}
  }
}
