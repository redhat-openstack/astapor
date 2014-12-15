class quickstack::neutron::all (
  $allow_overlapping_ips         = true,
  $auth_host                     = 'localhost',
  $auth_tenant                   = 'services',
  $auth_user                     = 'neutron',
  $cisco_nexus_plugin            = '',
  $cisco_vswitch_plugin          = '',
  $enable_tunneling              = true,
  $enabled                       = true,
  $external_network_bridge       = '',
  $database_max_retries          = '',
  $manage_service                = true,
  $ml2_type_drivers              = ['local', 'flat', 'vlan', 'gre', 'vxlan'],
  $ml2_tenant_network_types      = ['vxlan', 'vlan', 'gre', 'flat'],
  $ml2_mechanism_drivers         = ['openvswitch','l2population'],
  $ml2_flat_networks             = ['*'],
  $ml2_network_vlan_ranges       = ['yourphysnet:10:50'],
  $ml2_tunnel_id_ranges          = ['20:100'],
  $ml2_vxlan_group               = '224.0.0.1',
  $ml2_vni_ranges                = ['10:100'],
  $ml2_security_group            = 'True',
  $mysql_ca                      = undef,
  $mysql_host                    = '127.0.0.1',
  $neutron_core_plugin           = 'neutron.plugins.ml2.plugin.Ml2Plugin',
  $neutron_db_password,
  $neutron_metadata_proxy_secret,
  $neutron_priv_host             = '127.0.0.1',
  $neutron_url                   = '127.0.0.1',
  $neutron_user_password,
  $nexus_config                  = {},
  $nexus_credentials             = [],
  $neutron_conf_additional_params = { default_quota => 'default',
                                      quota_network => 'default',
                                      quota_subnet => 'default',
                                      quota_port => 'default',
                                      quota_security_group => 'default',
                                      quota_security_group_rule  => 'default',
                                      quota_vip => 'default',
                                      quota_pool => 'default',
                                      quota_router => 'default',
                                      quota_floatingip => 'default',
                                      network_auto_schedule => 'default',
                                    },
  $nova_conf_additional_params   = { quota_instances => 'default',
                                     quota_cores => 'default',
                                     quota_ram => 'default',
                                     quota_floating_ips => 'default',
                                     quota_fixed_ips => 'default',
                                     quota_driver => 'default',
                                     },
  $n1kv_plugin_additional_params = { default_policy_profile => 'default-pp',
                                     network_node_policy_profile => 'default-pp',
                                     poll_duration => '10',
                                     http_pool_size => '4',
                                     http_timeout => '120',
                                     firewall_driver => 'neutron.agent.firewall.NoopFirewallDriver',
                                     enable_sync_on_start => 'True',
                                     restrict_policy_profiles => 'False',
                                     },
  $n1kv_vsm_ip                   = '0.0.0.0',
  $n1kv_vsm_password             = undef,
  $ovs_bridge_mappings           = [],
  $ovs_bridge_uplinks            = [],
  $ovs_tunnel_iface              = '',
  $ovs_tunnel_network            = '',
  $ovs_vlan_ranges               = '',
  $ovs_vxlan_udp_port            = '4789',
  $ovs_tunnel_types              = [],
  $provider_vlan_auto_create     = '',
  $provider_vlan_auto_trunk      = '',
  $amqp_host                     = '127.0.0.1',
  $amqp_port                     = '5672',
  $amqp_ssl_port                 = '5671',
  $amqp_username                 = '',
  $amqp_password                 = '',
  $rpc_backend                   = 'neutron.openstack.common.rpc.impl_kombu',
  $security_group_api            = 'neutron',
  $tenant_network_type           = 'vlan',
  $network_device_mtu            = undef,
  $veth_mtu                      = undef,
  $verbose                       = 'false',
  $ssl                           = 'false',
) {

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
    allow_overlapping_ips => str2bool_i("$allow_overlapping_ips"),
    bind_host             => $neutron_priv_host,
    core_plugin           => $neutron_core_plugin,
    enabled               => str2bool_i("$enabled"),
    rpc_backend           => $rpc_backend,
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
    verbose               => $verbose,
    network_device_mtu    => $network_device_mtu,
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
  File['/etc/neutron/plugin.ini'] -> Exec['neutron-db-manage upgrade']

# This was moved out of keystone::endpoints and added here so the network replacement of neutron could work
  class { 'neutron::keystone::auth':
    password         => $neutron_user_password,
    public_address   => $neutron_public_real,
    public_protocol  => $public_protocol,
    admin_address    => $neutron_admin_real,
    internal_address => $neutron_internal_real,
    region           => $region,
  }
  contain neutron::keystone::auth

  class { '::neutron::server':
    auth_host            => $auth_host,
    auth_password        => $neutron_user_password,
    auth_tenant          => $auth_tenant,
    auth_user            => $auth_user,
    connection           => $sql_connection,
    database_max_retries => $database_max_retries,
    enabled              => str2bool_i("$enabled"),
    manage_service       => str2bool_i("$manage_service"),
  }
  contain neutron::server

  if $neutron_core_plugin == 'neutron.plugins.ml2.plugin.Ml2Plugin' {

    neutron_config {
      'DEFAULT/service_plugins':
        value => join(['neutron.services.l3_router.l3_router_plugin.L3RouterPlugin',]),
    }
    ->
    class { '::neutron::plugins::ml2':
      type_drivers          => $ml2_type_drivers,
      tenant_network_types  => $ml2_tenant_network_types,
      mechanism_drivers     => $ml2_mechanism_drivers,
      flat_networks         => $ml2_flat_networks,
      network_vlan_ranges   => $ml2_network_vlan_ranges,
      tunnel_id_ranges      => $ml2_tunnel_id_ranges,
      vxlan_group           => $ml2_vxlan_group,
      vni_ranges            => $ml2_vni_ranges,
      enable_security_group => $ml2_security_group,
    }

    # If cisco nexus is part of ml2 mechanism drivers,
    # setup Mech Driver Cisco Neutron plugin class.
    if ('cisco_nexus' in $ml2_mechanism_drivers) {
      class { 'neutron::plugins::ml2::cisco::nexus':
        nexus_config        => $nexus_config,
      }
    }
  }

  if $neutron_core_plugin == 'neutron.plugins.cisco.network_plugin.PluginV2' {
    class { 'quickstack::neutron::plugins::cisco':
      cisco_vswitch_plugin         => $cisco_vswitch_plugin,
      cisco_nexus_plugin           => $cisco_nexus_plugin,
      n1kv_vsm_ip                  => $n1kv_vsm_ip,
      n1kv_vsm_password            => $n1kv_vsm_password,
      n1kv_plugin_additional_params => $n1kv_plugin_additional_params,
      n1kv_os_ha                  => 'true',
      neutron_core_plugin          => $neutron_core_plugin,
      neutron_db_password          => $neutron_db_password,
      neutron_user_password        => $neutron_user_password,
      nexus_config                 => $nexus_config,
      nexus_credentials            => $nexus_credentials,
      mysql_host                   => $mysql_host,
      mysql_ca                     => $mysql_ca,
      ovs_vlan_ranges              => $ovs_vlan_ranges,
      provider_vlan_auto_create    => $provider_vlan_auto_create,
      provider_vlan_auto_trunk     => $provider_vlan_auto_trunk,
      tenant_network_type          => $tenant_network_type,
    }
  } else {
    $local_ip = find_ip("$ovs_tunnel_network",
                      ["$ovs_tunnel_iface","$external_network_bridge"],
                      "")
    class { '::neutron::agents::ovs':
      bridge_mappings  => $ovs_bridge_mappings,
      bridge_uplinks   => $ovs_bridge_uplinks,
      enabled          => str2bool_i("$enabled"),
      enable_tunneling => str2bool_i("$enable_tunneling"),
      local_ip         => $local_ip,
      manage_service   => str2bool_i("$manage_service"),
      tunnel_types     => $ovs_tunnel_types,
      vxlan_udp_port   => $ovs_vxlan_udp_port,
      veth_mtu         => $veth_mtu,
    }
  }

  class { '::nova::network::neutron':
    neutron_admin_password => $neutron_user_password,
    neutron_url            => "http://${neutron_url}:9696",
    neutron_admin_auth_url => "http://${auth_host}:35357/v2.0",
    security_group_api     => $security_group_api,
  }

  class { '::neutron::agents::dhcp':
    enabled        => str2bool_i("$enabled"),
    manage_service => str2bool_i("$manage_service"),
  }

  class { '::neutron::agents::l3':
    enabled                 => str2bool_i("$enabled"),
    external_network_bridge => $external_network_bridge,
    manage_service          => str2bool_i("$manage_service"),
  }

  class { 'neutron::agents::metadata':
    auth_password  => $neutron_user_password,
    auth_url       => "http://${auth_host}:35357/v2.0",
    enabled        => str2bool_i("$enabled"),
    manage_service => str2bool_i("$manage_service"),
    metadata_ip    => $neutron_priv_host,
    shared_secret  => $neutron_metadata_proxy_secret,
  }

  neutron_config {
    'DEFAULT/host': value => 'neutron-n-0';
  }

  include quickstack::neutron::notifications

  #class { 'neutron::agents::lbaas': }

  #class { 'neutron::agents::fwaas': }

  class {'quickstack::neutron::firewall::gre': }

  class {'quickstack::neutron::firewall::vxlan':
    port => $ovs_vxlan_udp_port,
  }

  class {'::quickstack::firewall::neutron':}

  class {'::quickstack::neutron::plugins::neutron_config':
    neutron_conf_additional_params => $neutron_conf_additional_params,
  }

  class {'::quickstack::neutron::plugins::nova_config':
    nova_conf_additional_params => $nova_conf_additional_params,
  }

}
