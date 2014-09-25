class quickstack::roles::nova::network::neutron (
) inherits quickstack::roles::params {
  class {'::nova::network::neutron':
    neutron_admin_password          => $neutron_admin_password,
    neutron_url                     => $neutron_url,
    neutron_admin_tenant_name       => 'services',
    neutron_default_tenant_id       => 'default',
    neutron_region_name             => $region,
    neutron_admin_username          => 'neutron',
    neutron_admin_auth_url          => $neutron_admin_auth_url,
    neutron_ovs_bridge              => 'br-int',
    security_group_api              => 'neutron',
  }
}
