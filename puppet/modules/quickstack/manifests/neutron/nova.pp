#
# == Class: quickstack::neutron::nova
#
# Configure neutron for nova network
#
# === Parameters
#
class quickstack::neutron::nova (
) inherits quickstack::params {

  class { '::nova::network::neutron':
    neutron_admin_password => $neutron_user_password,
    neutron_url            => "http://${neutron_url}:9696",
    neutron_admin_auth_url => "http://${auth_host}:35357/v2.0",
    security_group_api     => $security_group_api,
  }
}
