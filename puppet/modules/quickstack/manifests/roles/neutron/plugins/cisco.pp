class quickstack::roles::neutron::plugins::cisco (
  $ovs_vlan_ranges,
  $vswitch_plugin,
  $nexus_plugin,
  $provider_vlan_auto_create,
  $provider_vlan_auto_trunk,
  $tenant_network_type,
) inherits quickstack::roles::params {

  class { 'quickstack::neutron::plugins::cisco':
    neutron_db_password          => $neutron_db_password,
    neutron_user_password        => $neutron_user_password,
    ovs_vlan_ranges              => $ovs_vlan_ranges,
    cisco_vswitch_plugin         => $cisco_vswitch_plugin,
    nexus_config                 => $nexus_config,
    cisco_nexus_plugin           => $cisco_nexus_plugin,
    nexus_credentials            => $nexus_credentials,
    provider_vlan_auto_create    => $provider_vlan_auto_create,
    provider_vlan_auto_trunk     => $provider_vlan_auto_trunk,
    mysql_host                   => $mysql_vip,
    mysql_ca                     => $mysql_ca,
    tenant_network_type          => $cisco_tenant_network_type,
  }
}
