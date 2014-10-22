class quickstack::firewall::common {
  class { 'firewall': }

  Service['iptables'] -> Firewall<||>
}
