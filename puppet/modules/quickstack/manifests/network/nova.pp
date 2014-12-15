#
# == Class: quickstack::network::nova
#
# Configure neutron for nova network
#
# === Parameters
#
class quickstack::network::nova (
) inherits quickstack::network::params {

  class { '::nova::network::neutron':
    neutron_admin_password => $neutron_user_password,
    neutron_url            => "http://${neutron_vip_internal}:9696",
    neutron_admin_auth_url => "http://${keystone_vip_internal}:35357/v2.0",
    security_group_api     => $security_group_api,
  }
}
