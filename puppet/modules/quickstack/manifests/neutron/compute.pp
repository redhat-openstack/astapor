# Quickstack compute node configuration for neutron (OpenStack Networking)
class quickstack::neutron::compute (
  $admin_password              = $quickstack::params::admin_password,
  $ceilometer                  = 'true',
  $ceilometer_host             = 'false',
  $ceilometer_metering_secret  = $quickstack::params::ceilometer_metering_secret,
  $ceilometer_user_password    = $quickstack::params::ceilometer_user_password,
  $cinder_backend_gluster      = $quickstack::params::cinder_backend_gluster,
  $controller_admin_host       = $quickstack::params::controller_admin_host,
  $controller_priv_host        = $quickstack::params::controller_priv_host,
  $controller_pub_host         = $quickstack::params::controller_pub_host,
  $enable_tunneling            = $quickstack::params::enable_tunneling,
  $mysql_host                  = $quickstack::params::mysql_host,
  $neutron_core_plugin         = $quickstack::params::neutron_core_plugin,
  $neutron_db_password         = $quickstack::params::neutron_db_password,
  $neutron_user_password       = $quickstack::params::neutron_user_password,
  $nova_db_password            = $quickstack::params::nova_db_password,
  $nova_user_password          = $quickstack::params::nova_user_password,
  $ntp_servers                 = ['0.pool.ntp.org','1.pool.ntp.org','2.pool.ntp.org'],
  $ovs_bridge_mappings         = $quickstack::params::ovs_bridge_mappings,
  $ovs_vlan_ranges             = $quickstack::params::ovs_vlan_ranges,
  $ovs_tunnel_iface            = 'eth1',
  $ovs_tunnel_network          = '',
  $qpid_host                   = $quickstack::params::qpid_host,
  $qpid_username               = $quickstack::params::qpid_username,
  $qpid_password               = $quickstack::params::qpid_password,
  $tenant_network_type         = $quickstack::params::tenant_network_type,
  $tunnel_id_ranges            = '1:1000',
  $ovs_vxlan_udp_port          = $quickstack::params::ovs_vxlan_udp_port,
  $ovs_tunnel_types            = $quickstack::params::ovs_tunnel_types,
  $verbose                     = $quickstack::params::verbose,
  $ssl                         = $quickstack::params::ssl,
  $mysql_ca                    = $quickstack::params::mysql_ca,
  $use_qemu_for_poc            = $quickstack::params::use_qemu_for_poc,
) inherits quickstack::params {

  if str2bool_i("$ssl") {
    $qpid_protocol = 'ssl'
    $qpid_port = '5671'
    $sql_connection = "mysql://neutron:${neutron_db_password}@${mysql_host}/neutron?ssl_ca=${mysql_ca}"
  } else {
    $qpid_protocol = 'tcp'
    $qpid_port = '5672'
    $sql_connection = "mysql://neutron:${neutron_db_password}@${mysql_host}/neutron"
  }

  class { '::neutron':
    allow_overlapping_ips => true,
    rpc_backend           => 'neutron.openstack.common.rpc.impl_qpid',
    qpid_hostname         => $qpid_host,
    qpid_port             => $qpid_port,
    qpid_protocol         => $qpid_protocol,
    qpid_username         => $qpid_username,
    qpid_password         => $qpid_password,
    core_plugin           => $neutron_core_plugin
  }

  neutron_config {
    'database/connection': value => $sql_connection;
    'keystone_authtoken/auth_host':         value => $controller_priv_host;
    'keystone_authtoken/admin_tenant_name': value => 'services';
    'keystone_authtoken/admin_user':        value => 'neutron';
    'keystone_authtoken/admin_password':    value => $neutron_user_password;
  }

  class { '::neutron::plugins::ovs':
    sql_connection      => $sql_connection,
    tenant_network_type => $tenant_network_type,
    network_vlan_ranges => $ovs_vlan_ranges,
    tunnel_id_ranges    => $tunnel_id_ranges,
    vxlan_udp_port      => $ovs_vxlan_udp_port,
  }
  $local_ip = find_ip("$ovs_tunnel_network","$ovs_tunnel_iface","")
  class { '::neutron::agents::ovs':
    bridge_mappings     => $ovs_bridge_mappings,
    local_ip            => $local_ip,
    enable_tunneling    => str2bool_i("$enable_tunneling"),
    tunnel_types     => $ovs_tunnel_types,
    vxlan_udp_port   => $ovs_vxlan_udp_port,
  }

  class { '::nova::network::neutron':
    neutron_admin_password    => $neutron_user_password,
    neutron_url               => "http://${controller_priv_host}:9696",
    neutron_admin_auth_url    => "http://${controller_admin_host}:35357/v2.0",
  }


  class { 'quickstack::compute_common':
    admin_password             => $admin_password,
    ceilometer                 => $ceilometer,
    ceilometer_host            => $ceilometer_host,
    ceilometer_metering_secret => $ceilometer_metering_secret,
    ceilometer_user_password   => $ceilometer_user_password,
    cinder_backend_gluster     => $cinder_backend_gluster,
    controller_priv_host       => $controller_priv_host,
    controller_pub_host        => $controller_pub_host,
    mysql_host                 => $mysql_host,
    nova_db_password           => $nova_db_password,
    nova_user_password         => $nova_user_password,
    ntp_servers                => $ntp_servers,
    qpid_host                  => $qpid_host,
    qpid_username              => $qpid_username,
    qpid_password              => $qpid_password,
    verbose                    => $verbose,
    ssl                        => $ssl,
    mysql_ca                   => $mysql_ca,
    use_qemu_for_poc           => $use_qemu_for_poc,
  }

  class {'quickstack::neutron::firewall::vxlan':
    port => $ovs_vxlan_udp_port,
  }
}
