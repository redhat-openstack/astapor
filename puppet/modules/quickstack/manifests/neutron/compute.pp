# Quickstack compute node configuration for neutron (OpenStack Networking)
class quickstack::neutron::compute (
  $admin_password              = $quickstack::params::admin_password,
  $auth_host                   = '127.0.0.1',
  $ceilometer                  = 'true',
  $ceilometer_metering_secret  = $quickstack::params::ceilometer_metering_secret,
  $ceilometer_user_password    = $quickstack::params::ceilometer_user_password,
  $cinder_backend_gluster      = $quickstack::params::cinder_backend_gluster,
  $cinder_backend_nfs          = 'false',
  $glance_host                 = '127.0.0.1',
  $nova_host                   = '127.0.0.1',
  $enable_tunneling            = $quickstack::params::enable_tunneling,
  $mysql_host                  = $quickstack::params::mysql_host,
  $neutron_db_password         = $quickstack::params::neutron_db_password,
  $neutron_user_password       = $quickstack::params::neutron_user_password,
  $neutron_host                = '127.0.0.1',
  $nova_db_password            = $quickstack::params::nova_db_password,
  $nova_user_password          = $quickstack::params::nova_user_password,
  $ovs_bridge_mappings         = $quickstack::params::ovs_bridge_mappings,
  $ovs_bridge_uplinks          = $quickstack::params::ovs_bridge_uplinks,
  $ovs_vlan_ranges             = $quickstack::params::ovs_vlan_ranges,
  $ovs_tunnel_iface            = 'eth1',
  $ovs_tunnel_network          = '',
  $ovs_l2_population           = 'True',
  $amqp_provider               = $quickstack::params::amqp_provider,
  $amqp_host                   = $quickstack::params::amqp_host,
  $amqp_port                   = '5672',
  $amqp_ssl_port               = '5671',
  $amqp_username               = $quickstack::params::amqp_username,
  $amqp_password               = $quickstack::params::amqp_password,
  $tenant_network_type         = $quickstack::params::tenant_network_type,
  $tunnel_id_ranges            = '1:1000',
  $ovs_vxlan_udp_port          = $quickstack::params::ovs_vxlan_udp_port,
  $ovs_tunnel_types            = $quickstack::params::ovs_tunnel_types,
  $verbose                     = $quickstack::params::verbose,
  $ssl                         = $quickstack::params::ssl,
  $mysql_ca                    = $quickstack::params::mysql_ca,
) inherits quickstack::params {

  if str2bool_i("$ssl") {
    $qpid_protocol = 'ssl'
    $real_amqp_port = $amqp_ssl_port
    $sql_connection = "mysql://neutron:${neutron_db_password}@${mysql_host}/neutron?ssl_ca=${mysql_ca}"
  } else {
    $qpid_protocol = 'tcp'
    $real_amqp_port = $amqp_port
    $sql_connection = "mysql://neutron:${neutron_db_password}@${mysql_host}/neutron"
  }

  class { '::neutron':
    allow_overlapping_ips => true,
    rpc_backend           => amqp_backend('neutron', $amqp_provider),
    qpid_hostname         => $amqp_host,
    qpid_port             => $real_amqp_port,
    qpid_protocol         => $qpid_protocol,
    qpid_username         => $amqp_username,
    qpid_password         => $amqp_password,
    rabbit_host           => $amqp_host,
    rabbit_port           => $real_amqp_port,
    rabbit_user           => $amqp_username,
    rabbit_password       => $amqp_password,
    verbose               => $verbose,
  }
  ->
  class { '::neutron::server::notifications':
    notify_nova_on_port_status_changes => true,
    notify_nova_on_port_data_changes   => true,
    nova_url                           => "http://${nova_host}:8774/v2",
    nova_admin_auth_url                => "http://${auth_host}:35357/v2.0",
    nova_admin_username                => "nova",
    nova_admin_password                => "${nova_user_password}",
  }

  neutron_config {
    'database/connection':                  value => $sql_connection;
    'keystone_authtoken/auth_host':         value => $auth_host;
    'keystone_authtoken/admin_tenant_name': value => 'services';
    'keystone_authtoken/admin_user':        value => 'neutron';
    'keystone_authtoken/admin_password':    value => $neutron_user_password;
  }

  class { 'quickstack::neutron::controller':
    neutron_core_plugin  => $quickstack::neutron::controller::neutron_core_plugin;
  }

  if $neutron_core_plugin == 'neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2' {
    class { '::neutron::plugins::ovs':
      sql_connection      => $sql_connection,
      tenant_network_type => $tenant_network_type,
      network_vlan_ranges => $ovs_vlan_ranges,
      tunnel_id_ranges    => $tunnel_id_ranges,
      vxlan_udp_port      => $ovs_vxlan_udp_port,
    }

    neutron_plugin_ovs { 'AGENT/l2_population': value => "$ovs_l2_population"; }

    $local_ip = find_ip("$ovs_tunnel_network","$ovs_tunnel_iface","")
    class { '::neutron::agents::ovs':
      bridge_uplinks      => $ovs_bridge_uplinks,
      bridge_mappings     => $ovs_bridge_mappings,
      local_ip            => $local_ip,
      enable_tunneling    => str2bool_i("$enable_tunneling"),
      tunnel_types     => $ovs_tunnel_types,
      vxlan_udp_port   => $ovs_vxlan_udp_port,
    }
  }

  class { '::nova::network::neutron':
    neutron_admin_password => $neutron_user_password,
    neutron_url            => "http://${neutron_host}:9696",
    neutron_admin_auth_url => "http://${auth_host}:35357/v2.0",
  }


  class { 'quickstack::compute_common':
    admin_password             => $admin_password,
    auth_host                  => $auth_host,
    ceilometer                 => $ceilometer,
    ceilometer_metering_secret => $ceilometer_metering_secret,
    ceilometer_user_password   => $ceilometer_user_password,
    cinder_backend_gluster     => $cinder_backend_gluster,
    cinder_backend_nfs         => $cinder_backend_nfs,
    glance_host                => $glance_host,
    mysql_host                 => $mysql_host,
    nova_db_password           => $nova_db_password,
    nova_host                  => $nova_host,
    nova_user_password         => $nova_user_password,
    amqp_host                  => $amqp_host,
    amqp_port                  => $amqp_port,
    amqp_ssl_port              => $amqp_ssl_port,
    amqp_username              => $amqp_username,
    amqp_password              => $amqp_password,
    verbose                    => $verbose,
    ssl                        => $ssl,
    mysql_ca                   => $mysql_ca,
  }

  class {'quickstack::neutron::firewall::gre':}

  class {'quickstack::neutron::firewall::vxlan':
    port => $ovs_vxlan_udp_port,
  }
}
