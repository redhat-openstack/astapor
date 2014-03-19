class quickstack::neutron::firewall::vxlan (
  $port = 4789,
) {
  firewall { '002 vxlan udp':
    proto  => 'udp',
    dport  => ["${port}"],
    action => 'accept',
  }
}
