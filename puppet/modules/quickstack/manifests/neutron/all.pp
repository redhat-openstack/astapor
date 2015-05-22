class quickstack::neutron::all (
  $allow_overlapping_ips         = true,
  $auth_host                     = 'localhost',
  $auth_tenant                   = 'services',
  $auth_user                     = 'neutron',
  $dhcp_agents_per_network       = '1',
  $cisco_nexus_plugin            = '',
  $cisco_vswitch_plugin          = '',
  $enable_tunneling              = true,
  $enabled                       = true,
  $external_network_bridge       = '',
  $enable_vif_type_n1kv          = false,
  $database_max_retries          = '',
  $l3_ha                         = false,
  $manage_service                = true,
  $max_l3_agents_per_router      = 3,
  $min_l3_agents_per_router      = 2,
  $ml2_type_drivers              = ['local', 'flat', 'vlan', 'gre', 'vxlan'],
  $ml2_tenant_network_types      = ['vxlan', 'vlan', 'gre', 'flat'],
  $ml2_mechanism_drivers         = ['openvswitch'],
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
  $nova_conf_additional_params   = {quota_instances => 'default',
                                    quota_cores => 'default',
                                    quota_ram => 'default',
                                    quota_floating_ips => 'default',
                                    quota_fixed_ips => 'default',
                                    quota_driver => 'default',
                                    },
  $n1kv_plugin_additional_params = {default_policy_profile => 'default-pp',
                                    network_node_policy_profile => 'default-pp',
                                    poll_duration => '10',
                                    http_pool_size => '4',
                                    http_timeout => '120',
                                    firewall_driver => 'neutron.agent.firewall.NoopFirewallDriver',
                                    enable_sync_on_start => 'True',
                                    restrict_policy_profiles => 'False',
                                    },
  $n1kv_ml2_plugin_additional_params = {default_policy_profile => 'default-pp',
                                        default_vlan_network_profile => 'default-vlan-np',
                                        default_vxlan_network_profile => 'default-vxlan-np',
                                        poll_duration => '60',
                                        http_pool_size => '4',
                                        http_timeout => '15',
                                        restrict_policy_profiles => 'False',
                                        },
  $n1kv_vsm_ip                   = undef,
  $n1kv_vsm_password             = undef,
  $n1kv_vsm_username             = undef,
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
  $rabbit_hosts                  = undef,
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

  if $rabbit_hosts {
    neutron_config { 'DEFAULT/rabbit_host': ensure => absent }
    neutron_config { 'DEFAULT/rabbit_port': ensure => absent }
  }

  class { '::neutron':
    allow_overlapping_ips   => str2bool_i("$allow_overlapping_ips"),
    bind_host               => $neutron_priv_host,
    core_plugin             => $neutron_core_plugin,
    dhcp_agents_per_network => $dhcp_agents_per_network,
    enabled                 => str2bool_i("$enabled"),
    rpc_backend             => $rpc_backend,
    qpid_hostname           => $amqp_host,
    qpid_port               => $real_amqp_port,
    qpid_protocol           => $qpid_protocol,
    qpid_username           => $amqp_username,
    qpid_password           => $amqp_password,
    rabbit_host             => $amqp_host,
    rabbit_port             => $real_amqp_port,
    rabbit_user             => $amqp_username,
    rabbit_password         => $amqp_password,
    rabbit_use_ssl          => $ssl,
    rabbit_hosts            => $rabbit_hosts,
    verbose                 => $verbose,
    network_device_mtu      => $network_device_mtu,
  }

  # short-term workaround for BZ 1181592
  package{'bind-utils': } ->
  exec {'neutron-etc-hosts-workaround':
    command => 'dig A $(hostname) | grep -A1 "ANSWER SEC" | tail -n 1 | awk \'{print $NF " " $1}\' | sed -e \'s/.$//g\' >>/etc/hosts',
    unless => 'grep -P "\b$( hostname )\b" /etc/hosts',
    path => ['/usr/bin','/bin'],
  } -> Service['neutron-server']

  if ('cisco_n1kv' in $ml2_mechanism_drivers) {
    neutron_config {
      'DEFAULT/service_plugins':
        value => join(['cisco_n1kv_profile','neutron.services.l3_router.l3_router_plugin.L3RouterPlugin'], ','),
    }
  } else {
    neutron_config {
      'DEFAULT/service_plugins':
        value => join(['neutron.services.l3_router.l3_router_plugin.L3RouterPlugin',]),
    }
  }

  anchor {'quickstack-neutron-server-first':}
  ->
  class { '::neutron::server':
    auth_host                => $auth_host,
    auth_password            => $neutron_user_password,
    auth_tenant              => $auth_tenant,
    auth_user                => $auth_user,
    database_connection      => $sql_connection,
    database_max_retries     => $database_max_retries,
    enabled                  => str2bool_i("$enabled"),
    l3_ha                    => str2bool_i("$l3_ha"),
    manage_service           => str2bool_i("$manage_service"),
    max_l3_agents_per_router => $max_l3_agents_per_router,
    min_l3_agents_per_router => $min_l3_agents_per_router,
    sync_db                  => true,
  }
  ->
  anchor {'quickstack-neutron-server-last':}

  if $neutron_core_plugin == 'neutron.plugins.ml2.plugin.Ml2Plugin' {

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
    } elsif ('cisco_n1kv' in $ml2_mechanism_drivers) {
      class { 'quickstack::neutron::plugins::nexus1000v':
        default_policy_profile               => $n1kv_ml2_plugin_additional_params[default_policy_profile],
        default_vlan_network_profile         => $n1kv_ml2_plugin_additional_params[default_vlan_network_profile],
        default_vxlan_network_profile        => $n1kv_ml2_plugin_additional_params[default_vxlan_network_profile],
        enable_vif_type_n1kv                 => $enable_vif_type_n1kv,
        poll_duration                        => $n1kv_ml2_plugin_additional_params[poll_duration],
        http_pool_size                       => $n1kv_ml2_plugin_additional_params[http_pool_size],
        http_timeout                         => $n1kv_ml2_plugin_additional_params[http_timeout],
        n1kv_vsm_ip                          => $n1kv_vsm_ip,
        n1kv_vsm_password                    => $n1kv_vsm_password,
        n1kv_vsm_username                    => $n1kv_vsm_username,
        restrict_policy_profiles             => $n1kv_ml2_plugin_additional_params[restrict_policy_profiles],
      }
    }
  }

  if ($neutron_core_plugin == "neutron.plugins.cisco.network_plugin.PluginV2") {
    class { 'quickstack::neutron::plugins::cisco':
      cisco_vswitch_plugin         => $cisco_vswitch_plugin,
      cisco_nexus_plugin           => $cisco_nexus_plugin,
      n1kv_vsm_ip                  => $n1kv_vsm_ip,
      n1kv_vsm_password            => $n1kv_vsm_password,
      n1kv_plugin_additional_params => $n1kv_plugin_additional_params,
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
    if ('cisco_n1kv' in $ml2_mechanism_drivers) {
      $_enable_tunneling  = false
      $local_ip = false
    } else {
      $_enable_tunneling  = str2bool_i("$enable_tunneling")
      $local_ip = find_ip("$ovs_tunnel_network",
                      ["$ovs_tunnel_iface","$external_network_bridge"],
                      "")
    }

    if str2bool_i("$l3_ha") {
      $_ovs_l2_population = 'False'
    } else {
      $_ovs_l2_population = 'True'
    }
    neutron_plugin_ovs {'AGENT/l2_population': value => "$_ovs_l2_population"; }

    class { '::neutron::agents::ovs':
      bridge_mappings  => $ovs_bridge_mappings,
      bridge_uplinks   => $ovs_bridge_uplinks,
      enabled          => str2bool_i("$enabled"),
      enable_tunneling => $_enable_tunneling,
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

  if $enable_vif_type_n1kv {
    $_interface_driver = "neutron.agent.linux.interface.N1KVInterfaceDriver"
  } else {
    $_interface_driver = "neutron.agent.linux.interface.OVSInterfaceDriver"
  }

  class { '::neutron::agents::dhcp':
    enabled          => str2bool_i("$enabled"),
    manage_service   => str2bool_i("$manage_service"),
    interface_driver => $_interface_driver,
  }

  class { '::neutron::agents::l3':
    enabled                 => str2bool_i("$enabled"),
    external_network_bridge => $external_network_bridge,
    manage_service          => str2bool_i("$manage_service"),
    interface_driver        => $_interface_driver,
  }

  class { 'neutron::agents::metadata':
    auth_password  => $neutron_user_password,
    auth_url       => "http://${auth_host}:35357/v2.0",
    enabled        => str2bool_i("$enabled"),
    manage_service => str2bool_i("$manage_service"),
    metadata_ip    => $neutron_priv_host,
    shared_secret  => $neutron_metadata_proxy_secret,
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
