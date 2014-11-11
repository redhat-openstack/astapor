#
# == Class: quickstack::roles::neutron::upgrade
#
# Upgrade neutron server (API)
#
# === Parameters
#
class quickstack::roles::neutron::server::upgrade (
) inherits quickstack::roles::params {

  # FIXME: This really should be handled by the neutron-puppet module, which has
  # a review request open right now: https://review.openstack.org/#/c/50162/
  # If and when that is merged (or similar), the below can be removed.
  exec { 'neutron-db-manage upgrade':
    command     => 'neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini upgrade head',
    path        => '/usr/bin',
    user        => 'neutron',
    logoutput   => 'on_failure',
    before      => Service['neutron-server'],
    require     => [Neutron_config['database/connection'], Neutron_config['DEFAULT/core_plugin']],
  }

  File['/etc/neutron/plugin.ini'] -> Exec['neutron-db-manage upgrade']
}
