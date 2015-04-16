# Quickstack compute node configuration for neutron (OpenStack Networking)
class quickstack::neutron::compute (
  $agent_type                   = 'ovs',
  $auth_host                    = '127.0.0.1',
  $ceilometer                   = 'true',
  $ceilometer_metering_secret   = $quickstack::params::ceilometer_metering_secret,
  $ceilometer_user_password     = $quickstack::params::ceilometer_user_password,
  $manage_ceph_conf             = true,
  $ceph_cluster_network         = '',
  $ceph_public_network          = '',
  $ceph_fsid                    = '',
  $ceph_images_key              = '',
  $ceph_volumes_key             = '',
  $ceph_rgw_key                 = '',
  $ceph_mon_host                = [ ],
  $ceph_mon_initial_members     = [ ],
  $ceph_conf_include_osd_global = true,
  $ceph_osd_pool_size           = '',
  $ceph_osd_journal_size        = '',
  $ceph_osd_mkfs_options_xfs    = '-f -i size=2048 -n size=64k',
  $ceph_osd_mount_options_xfs   = 'inode64,noatime,logbsize=256k',
  $ceph_conf_include_rgw        = false,
  $ceph_rgw_hostnames           = [ ],
  $ceph_extra_conf_lines        = [ ],
  $cinder_backend_gluster       = $quickstack::params::cinder_backend_gluster,
  $cinder_backend_nfs           = 'false',
  $cinder_backend_rbd           = 'false',
  $cinder_catalog_info          = 'volume:cinder:internalURL',
  $glance_backend_rbd           = 'false',
  $glance_host                  = '127.0.0.1',
  $nova_host                    = '127.0.0.1',
  $enable_tunneling             = $quickstack::params::enable_tunneling,
  $mysql_host                   = $quickstack::params::mysql_host,
  $neutron_db_password          = $quickstack::params::neutron_db_password,
  $neutron_user_password        = $quickstack::params::neutron_user_password,
  $neutron_host                 = '127.0.0.1',
  $nova_db_password             = $quickstack::params::nova_db_password,
  $nova_user_password           = $quickstack::params::nova_user_password,
  $ovs_bridge_mappings          = $quickstack::params::ovs_bridge_mappings,
  $ovs_bridge_uplinks           = $quickstack::params::ovs_bridge_uplinks,
  $ovs_vlan_ranges              = $quickstack::params::ovs_vlan_ranges,
  $ovs_tunnel_iface             = 'eth1',
  $ovs_tunnel_network           = '',
  $ovs_l2_population            = 'False',
  $amqp_provider                = $quickstack::params::amqp_provider,
  $amqp_host                    = $quickstack::params::amqp_host,
  $amqp_port                    = '5672',
  $amqp_ssl_port                = '5671',
  $amqp_username                = $quickstack::params::amqp_username,
  $amqp_password                = $quickstack::params::amqp_password,
  $rabbit_hosts                 = [ ],
  $rabbitmq_use_addrs_not_vip   = true,
  $tenant_network_type          = $quickstack::params::tenant_network_type,
  $tunnel_id_ranges             = '1:1000',
  $ovs_vxlan_udp_port           = $quickstack::params::ovs_vxlan_udp_port,
  $ovs_tunnel_types             = $quickstack::params::ovs_tunnel_types,
  $verbose                      = $quickstack::params::verbose,
  $ssl                          = $quickstack::params::ssl,
  $security_group_api           = 'neutron',
  $mysql_ca                     = $quickstack::params::mysql_ca,
  $libvirt_images_rbd_pool      = 'volumes',
  $libvirt_images_rbd_ceph_conf = '/etc/ceph/ceph.conf',
  $libvirt_inject_password      = 'false',
  $libvirt_inject_key           = 'false',
  $libvirt_images_type          = 'rbd',
  $rbd_user                     = 'volumes',
  $rbd_secret_uuid              = '',
  $private_iface                = '',
  $private_ip                   = '',
  $private_network              = '',
  $network_device_mtu           = undef,
  $veth_mtu                     = undef,
  $vnc_keymap                   = 'en-us',
  $vncproxy_host                = undef,
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

  # empty array is true in puppet, so deal with that case the long
  # way.  the var $rabbitmq_use_addrs_not_vip provided for consistency
  # with the HA controller.
  if $rabbit_hosts == [ ]  or ! str2bool_i($rabbitmq_use_addrs_not_vip) {
    $_rabbit_hosts = undef
  } else {
    $_rabbit_hosts = split(inline_template('<%= @rabbit_hosts.map {
      |x| x+":"+@amqp_port }.join(",")%>'),",")
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
    rabbit_use_ssl        => $ssl,
    rabbit_hosts          => $_rabbit_hosts,
    verbose               => $verbose,
    network_device_mtu    => $network_device_mtu,
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

  if $_rabbit_hosts {
    neutron_config { 'DEFAULT/rabbit_host': ensure => absent }
    neutron_config { 'DEFAULT/rabbit_port': ensure => absent }
  }

  if downcase("$agent_type") == 'ovs' {
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
      tunnel_types        => $ovs_tunnel_types,
      vxlan_udp_port      => $ovs_vxlan_udp_port,
      veth_mtu            => $veth_mtu,
    }
  }

  class { '::nova::network::neutron':
    neutron_admin_password => $neutron_user_password,
    neutron_url            => "http://${neutron_host}:9696",
    neutron_admin_auth_url => "http://${auth_host}:35357/v2.0",
    security_group_api     => $security_group_api,
  }


  class { 'quickstack::compute_common':
    auth_host                    => $auth_host,
    ceilometer                   => $ceilometer,
    ceilometer_metering_secret   => $ceilometer_metering_secret,
    ceilometer_user_password     => $ceilometer_user_password,
    manage_ceph_conf             => $manage_ceph_conf,
    ceph_cluster_network         => $ceph_cluster_network,
    ceph_public_network          => $ceph_public_network,
    ceph_fsid                    => $ceph_fsid,
    ceph_images_key              => $ceph_images_key,
    ceph_volumes_key             => $ceph_volumes_key,
    ceph_rgw_key                 => $ceph_rgw_key,
    ceph_mon_host                => $ceph_mon_host,
    ceph_mon_initial_members     => $ceph_mon_initial_members,
    ceph_conf_include_osd_global => $ceph_conf_include_osd_global,
    ceph_osd_pool_size           => $ceph_osd_pool_size,
    ceph_osd_journal_size        => $ceph_osd_journal_size,
    ceph_osd_mkfs_options_xfs    => $ceph_osd_mkfs_options_xfs,
    ceph_osd_mount_options_xfs   => $ceph_osd_mount_options_xfs,
    ceph_conf_include_rgw        => $ceph_conf_include_rgw,
    ceph_rgw_hostnames           => $ceph_rgw_hostnames,
    ceph_extra_conf_lines        => $ceph_extra_conf_lines,
    cinder_backend_gluster       => $cinder_backend_gluster,
    cinder_backend_nfs           => $cinder_backend_nfs,
    cinder_backend_rbd           => $cinder_backend_rbd,
    cinder_catalog_info          => $cinder_catalog_info,
    glance_backend_rbd           => $glance_backend_rbd,
    glance_host                  => $glance_host,
    mysql_host                   => $mysql_host,
    nova_db_password             => $nova_db_password,
    nova_host                    => $nova_host,
    vncproxy_host                => pick($vncproxy_host, $nova_host),
    nova_user_password           => $nova_user_password,
    amqp_provider                => $amqp_provider,
    amqp_host                    => $amqp_host,
    amqp_port                    => $amqp_port,
    amqp_ssl_port                => $amqp_ssl_port,
    amqp_username                => $amqp_username,
    amqp_password                => $amqp_password,
    rabbit_hosts                 => $_rabbit_hosts,
    verbose                      => $verbose,
    ssl                          => $ssl,
    mysql_ca                     => $mysql_ca,
    libvirt_images_rbd_pool      => $libvirt_images_rbd_pool,
    libvirt_images_rbd_ceph_conf => $libvirt_images_rbd_ceph_conf,
    libvirt_inject_password      => $libvirt_inject_password,
    libvirt_inject_key           => $libvirt_inject_key,
    libvirt_images_type          => $libvirt_images_type,
    rbd_user                     => $rbd_user,
    rbd_secret_uuid              => $rbd_secret_uuid,
    private_iface                => $private_iface,
    private_ip                   => $private_ip,
    private_network              => $private_network,
    network_device_mtu           => $network_device_mtu,
    vnc_keymap                   => $vnc_keymap,
  }

  class {'quickstack::neutron::firewall::gre':}

  class {'quickstack::neutron::firewall::vxlan':
    port => $ovs_vxlan_udp_port,
  }
}
