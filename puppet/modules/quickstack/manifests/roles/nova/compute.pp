class quickstack::roles::nova::compute (
  $private_network,
  $private_iface,
  $private_ip,
) inherits quickstack::roles::params {

  $compute_ip = find_ip("$private_network",
                        "$private_iface",
                        "$private_ip")

  class { '::nova::compute':
    enabled => true,
    vncproxy_host => $nova_vip_private,
    vncserver_proxyclient_address => $compute_ip,
  }

  # TODO
  firewall { '001 nova compute incoming':
    proto  => 'tcp',
    dport  => '5900-5999',
    action => 'accept',
  }
}
