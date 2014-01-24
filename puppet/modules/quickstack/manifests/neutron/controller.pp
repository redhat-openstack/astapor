# Quickstart controller class for nova neutron (OpenStack Networking)
class quickstack::neutron::controller (
  $admin_email                   = $quickstack::params::admin_email,
  $admin_password                = $quickstack::params::admin_password,
  $ceilometer_metering_secret    = $quickstack::params::ceilometer_metering_secret,
  $ceilometer_user_password      = $quickstack::params::ceilometer_user_password,
  $cinder_backend_gluster        = $quickstack::params::cinder_backend_gluster,
  $cinder_backend_iscsi          = $quickstack::params::cinder_backend_iscsi,
  $cinder_db_password            = $quickstack::params::cinder_db_password,
  $cinder_gluster_servers        = $quickstack::params::cinder_gluster_servers,
  $cinder_gluster_volume         = $quickstack::params::cinder_gluster_volume,
  $cinder_user_password          = $quickstack::params::cinder_user_password,
  $cisco_nexus_plugin            = $quickstack::params::cisco_nexus_plugin,
  $cisco_vswitch_plugin          = $quickstack::params::cisco_vswitch_plugin,
  $controller_priv_host          = $quickstack::params::controller_priv_host,
  $controller_pub_host           = $quickstack::params::controller_pub_host,
  $glance_db_password            = $quickstack::params::glance_db_password,
  $glance_user_password          = $quickstack::params::glance_user_password,
  $heat_cfn                      = $quickstack::params::heat_cfn,
  $heat_cloudwatch               = $quickstack::params::heat_cloudwatch,
  $heat_db_password              = $quickstack::params::heat_db_password,
  $heat_user_password            = $quickstack::params::heat_user_password,
  $horizon_secret_key            = $quickstack::params::horizon_secret_key,
  $keystone_admin_token          = $quickstack::params::keystone_admin_token,
  $keystone_db_password          = $quickstack::params::keystone_db_password,
  $neutron_metadata_proxy_secret = $quickstack::params::neutron_metadata_proxy_secret,
  $mysql_host                    = $quickstack::params::mysql_host,
  $mysql_root_password           = $quickstack::params::mysql_root_password,
  $neutron_core_plugin           = $quickstack::params::neutron_core_plugin,
  $neutron_db_password           = $quickstack::params::neutron_db_password,
  $neutron_user_password         = $quickstack::params::neutron_user_password,
  $nexus_config                  = $quickstack::params::nexus_config,
  $nexus_credentials             = $quickstack::params::nexus_credentials,
  $nova_db_password              = $quickstack::params::nova_db_password,
  $nova_user_password            = $quickstack::params::nova_user_password,
  $ovs_vlan_ranges               = $quickstack::params::ovs_vlan_ranges,
  $provider_vlan_auto_create     = $quickstack::params::provider_vlan_auto_create,
  $provider_vlan_auto_trunk      = $quickstack::params::provider_vlan_auto_trunk,
  $enable_tunneling              = $quickstack::params::enable_tunneling,
  $tunnel_id_ranges              = '1:1000',
  $qpid_host                     = $quickstack::params::qpid_host,
  $swift_shared_secret           = $quickstack::params::swift_shared_secret,
  $swift_admin_password          = $quickstack::params::swift_admin_password,
  $tenant_network_type           = $quickstack::params::tenant_network_type,
  $verbose                       = $quickstack::params::verbose,
  $ssl                           = $quickstack::params::ssl,
  $freeipa                       = $quickstack::params::freeipa,
  $mysql_ca                      = $quickstack::params::mysql_ca,
  $mysql_cert                    = $quickstack::params::mysql_cert,
  $mysql_key                     = $quickstack::params::mysql_key,
  $qpid_ca                       = $quickstack::params::qpid_ca,
  $qpid_cert                     = $quickstack::params::qpid_cert,
  $qpid_key                      = $quickstack::params::qpid_key,
  $horizon_ca                    = $quickstack::params::horizon_ca,
  $horizon_cert                  = $quickstack::params::horizon_cert,
  $horizon_key                   = $quickstack::params::horizon_key,
  $qpid_nssdb_password           = $quickstack::params::qpid_nssdb_password,
) inherits quickstack::params {

  if str2bool($ssl) == true {
    $qpid_protocol = 'ssl'
    $qpid_port = '5671'
    $sql_connection = "mysql://neutron:${neutron_db_password}@${mysql_host}/neutron?ssl_ca=${mysql_ca}"
  } else {
    $qpid_protocol = 'tcp'
    $qpid_port = '5672'
    $sql_connection = "mysql://neutron:${neutron_db_password}@${mysql_host}/neutron"
  }

  class { 'quickstack::controller_common':
    admin_email                   => $admin_email,
    admin_password                => $admin_password,
    ceilometer_metering_secret    => $ceilometer_metering_secret,
    ceilometer_user_password      => $ceilometer_user_password,
    cinder_backend_gluster        => $cinder_backend_gluster,
    cinder_backend_iscsi          => $cinder_backend_iscsi,
    cinder_db_password            => $cinder_db_password,
    cinder_gluster_servers        => $cinder_gluster_servers,
    cinder_gluster_volume         => $cinder_gluster_volume,
    cinder_user_password          => $cinder_user_password,
    controller_priv_host          => $controller_priv_host,
    controller_pub_host           => $controller_pub_host,
    glance_db_password            => $glance_db_password,
    glance_user_password          => $glance_user_password,
    heat_cfn                      => $heat_cfn,
    heat_cloudwatch               => $heat_cloudwatch,
    heat_db_password              => $heat_db_password,
    heat_user_password            => $heat_user_password,
    horizon_secret_key            => $horizon_secret_key,
    keystone_admin_token          => $keystone_admin_token,
    keystone_db_password          => $keystone_db_password,
    neutron_metadata_proxy_secret => $neutron_metadata_proxy_secret,
    mysql_host                    => $mysql_host,
    mysql_root_password           => $mysql_root_password,
    neutron                       => true,
    neutron_core_plugin           => $neutron_core_plugin,
    neutron_db_password           => $neutron_db_password,
    neutron_user_password         => $neutron_user_password,
    nova_db_password              => $nova_db_password,
    nova_user_password            => $nova_user_password,
    qpid_host                     => $qpid_host,
    swift_shared_secret           => $swift_shared_secret,
    swift_admin_password          => $swift_admin_password,
    verbose                       => $verbose,
    ssl                           => $ssl,
    freeipa                       => $freeipa,
    mysql_ca                      => $mysql_ca,
    mysql_cert                    => $mysql_cert,
    mysql_key                     => $mysql_key,
    qpid_ca                       => $qpid_ca,
    qpid_cert                     => $qpid_cert,
    qpid_key                      => $qpid_key,
    horizon_ca                    => $horizon_ca,
    horizon_cert                  => $horizon_cert,
    horizon_key                   => $horizon_key,
    qpid_nssdb_password           => $qpid_nssdb_password,
  }
  ->
  class { '::neutron':
    enabled               => true,
    verbose               => $verbose,
    allow_overlapping_ips => true,
    rpc_backend           => 'neutron.openstack.common.rpc.impl_qpid',
    qpid_hostname         => $qpid_host,
    qpid_port             => $qpid_port,
    qpid_protocol         => $qpid_protocol,
    core_plugin           => $neutron_core_plugin
  }
  ->
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

  class { '::neutron::server':
    auth_host        => $::ipaddress,
    auth_password    => $neutron_user_password,
    connection       => $sql_connection,
    sql_connection   => false,
  }


  if $neutron_core_plugin == 'neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2' {
    neutron_plugin_ovs {
      'OVS/enable_tunneling': value => $enable_tunneling;
      'SECURITYGROUP/firewall_driver':
      value => 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver';
    }

    class { '::neutron::plugins::ovs':
      sql_connection      => $sql_connection,
      tenant_network_type => $tenant_network_type,
      network_vlan_ranges => $ovs_vlan_ranges,
      tunnel_id_ranges    => $tunnel_id_ranges,
    }
  }

  if $neutron_core_plugin == 'neutron.plugins.cisco.network_plugin.PluginV2' {
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
      mysql_host                   => $mysql_host,
      mysql_ca                     => $mysql_ca,
      tenant_network_type          => $tenant_network_type,
    }
  }

  class { '::nova::network::neutron':
    neutron_admin_password    => $neutron_user_password,
  }

  firewall { '001 neutron server (API)':
    proto    => 'tcp',
    dport    => ['9696'],
    action   => 'accept',
  }
}
