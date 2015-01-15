class quickstack::firewall::redis(
  $ports = ['6379'],
) {

  include quickstack::firewall::common

  firewall { '001 redis incoming':
    proto  => 'tcp',
    dport  => $ports,
    action => 'accept',
  }
}
