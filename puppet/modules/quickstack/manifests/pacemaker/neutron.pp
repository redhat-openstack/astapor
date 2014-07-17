class quickstack::pacemaker::neutron (
  $core_plugin                = 'neutron.plugins.ml2.plugin.Ml2Plugin',
  $enable_tunneling           = false,
  $enabled                    = true,
  $external_network_bridge    = 'br-ex',
  $ml2_type_drivers           = ['local', 'flat', 'vlan', 'gre', 'vxlan'],
  $ml2_tenant_network_types   = ['vxlan', 'vlan', 'gre', 'flat'],
  $ml2_mechanism_drivers      = ['openvswitch','l2population'],
  $ml2_flat_networks          = ['*'],
  $ml2_network_vlan_ranges    = ['yourphysnet:10:50'],
  $ml2_security_group         = 'True',
  $ml2_tunnel_id_ranges       = ['20:100'],
  $ml2_vxlan_group            = '224.0.0.1',
  $ovs_bridge_mappings        = [],
  $ovs_bridge_uplinks         = [],
  $ovs_tunnel_iface           = '',
  $ovs_tunnel_network         = '',
  $ovs_vxlan_udp_port         = '4789',
  $ovs_vlan_ranges            = '',
  $ovs_tunnel_types           = [],
  $tenant_network_type        = 'vlan',
  $tunnel_id_ranges           = '1:1000',
  $verbose                    = 'false',
) {
  include quickstack::pacemaker::common

  if (map_params('include_neutron') == 'true') {
    $neutron_group = map_params("neutron_group")
    $neutron_public_vip = map_params("neutron_public_vip")
    $ovs_nic = find_nic("$ovs_tunnel_network","$ovs_tunnel_iface","")

    if (map_params('include_mysql') == 'true') {
      Exec['all-galera-nodes-are-up'] -> Exec['i-am-neutron-vip-OR-neutron-is-up-on-vip']
    }
    if (map_params('include_keystone') == 'true') {
      Exec['all-keystone-nodes-are-up'] -> Exec['i-am-neutron-vip-OR-neutron-is-up-on-vip']
    }
    if (map_params('include_swift') == 'true') {
      Exec['all-swift-nodes-are-up'] -> Exec['i-am-neutron-vip-OR-neutron-is-up-on-vip']
    }
    if (map_params('include_cinder') == 'true') {
      Exec['all-cinder-nodes-are-up'] -> Exec['i-am-neutron-vip-OR-neutron-is-up-on-vip']
    }
    if (map_params('include_glance') == 'true') {
      Exec['all-glance-nodes-are-up'] -> Exec['i-am-neutron-vip-OR-neutron-is-up-on-vip']
    }
    if (map_params('include_nova') == 'true') {
      Exec['all-nova-nodes-are-up'] -> Exec['i-am-neutron-vip-OR-neutron-is-up-on-vip']
    }

    class {"::quickstack::load_balancer::neutron":
      frontend_pub_host    => map_params("neutron_public_vip"),
      frontend_priv_host    => map_params("neutron_private_vip"),
      frontend_admin_host    => map_params("neutron_admin_vip"),
      backend_server_names => map_params("lb_backend_server_names"),
      backend_server_addrs => map_params("lb_backend_server_addrs"),
    }

    Class['::quickstack::pacemaker::common']
    ->
    quickstack::pacemaker::vips { "$neutron_group":
      public_vip  => map_params("neutron_public_vip"),
      private_vip => map_params("neutron_private_vip"),
      admin_vip   => map_params("neutron_admin_vip"),
    }
    ->
    exec {"i-am-neutron-vip-OR-neutron-is-up-on-vip":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/tmp/ha-all-in-one-util.bash i_am_vip $neutron_public_vip || /tmp/ha-all-in-one-util.bash property_exists neutron",
      unless   => "/tmp/ha-all-in-one-util.bash i_am_vip $neutron_public_vip || /tmp/ha-all-in-one-util.bash property_exists neutron",
    }
    ->
    class { 'quickstack::neutron::all':
      auth_host                     => map_params("keystone_public_vip"),
      enable_tunneling              => $enable_tunneling,
      enabled                       => $enabled,
      external_network_bridge       => $external_network_bridge,
      ml2_type_drivers              => $ml2_type_drivers,
      ml2_tenant_network_types      => $ml2_tenant_network_types,
      ml2_mechanism_drivers         => $ml2_mechanism_drivers,
      ml2_flat_networks             => $ml2_flat_networks,
      ml2_network_vlan_ranges       => $ml2_network_vlan_ranges,
      ml2_tunnel_id_ranges          => $ml2_tunnel_id_ranges,
      ml2_vxlan_group               => $ml2_vxlan_group,
      ml2_vni_ranges                => $ml2_vni_ranges,
      ml2_security_group            => $ml2_security_group,
      mysql_host                    => map_params("db_vip"),
      neutron_core_plugin           => $core_plugin,
      neutron_db_password           => map_params("neutron_db_password"),
      neutron_priv_host             => map_params("local_bind_addr"),
      neutron_url                   => map_params("neutron_public_vip"),
      neutron_user_password         => map_params("neutron_user_password"),
      neutron_metadata_proxy_secret => map_params("neutron_metadata_proxy_secret"),
      ovs_bridge_mappings           => $ovs_bridge_mappings,
      ovs_bridge_uplinks            => $ovs_bridge_uplinks,
      ovs_tunnel_iface              => $ovs_nic,
      ovs_vlan_ranges               => $ovs_vlan_ranges,
      ovs_vxlan_udp_port            => $ovs_vxlan_udp_port,
      ovs_tunnel_types              => $ovs_tunnel_types,
      rpc_backend                   => amqp_backend('neutron', map_params('amqp_provider')),
      amqp_host                     => map_params("amqp_vip"),
      amqp_port                     => map_params("amqp_port"),
      amqp_username                 => map_params("amqp_username"),
      amqp_password                 => map_params("amqp_password"),
      tenant_network_type           => $tenant_network_type,
      verbose                       => $verbose,
    }
    ->
    exec {"pcs-neutron-server-set-up":
      command => "/usr/sbin/pcs property set neutron=running --force",
    } ->
    exec {"pcs-neutron-server-set-up-on-this-node":
      command => "/tmp/ha-all-in-one-util.bash update_my_node_property neutron"
    } ->
    exec {"all-neutron-nodes-are-up":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/tmp/ha-all-in-one-util.bash all_members_include neutron",
    }
    ->
    quickstack::pacemaker::resource::service {'neutron-server':
      clone => true,
      monitor_params => { 'start-delay' => '10s' },
    }
    ->
    quickstack::pacemaker::resource::ocf {'neutron-ovs-cleanup':
      resource_name => 'neutron:OVSCleanup',
      clone         => true,
    }
    ->
    quickstack::pacemaker::resource::ocf {'neutron-netns-cleanup':
      resource_name => 'neutron:NetnsCleanup',
      clone         => true,
    }
    ->
    quickstack::pacemaker::resource::service {'neutron-openvswitch-agent':
      group => "neutron-agents",
      clone => false,
      monitor_params => { 'start-delay' => '10s' },
    }
    ->
    quickstack::pacemaker::resource::service {'neutron-dhcp-agent':
      group => "neutron-agents",
      clone => false,
      monitor_params => { 'start-delay' => '10s' },
    }
    ->
    quickstack::pacemaker::resource::service {'neutron-l3-agent':
      group => "neutron-agents",
      clone => false,
      monitor_params => { 'start-delay' => '10s' },
    }
    ->
    quickstack::pacemaker::resource::service {'neutron-metadata-agent':
      group => "neutron-agents",
      clone => false,
      monitor_params => { 'start-delay' => '10s' },
    }
    ->
    quickstack::pacemaker::constraint::base { 'neutron-ovs-to-netns-cleanup-constr' :
      constraint_type => "order",
      first_resource  => "neutron-ovs-cleanup",
      second_resource => "neutron-netns-cleanup",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    quickstack::pacemaker::constraint::base { 'neutron-cleanup-to-agents-constr' :
      constraint_type => "order",
      first_resource  => "neutron-netns-cleanup",
      second_resource => "neutron-agents",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    quickstack::pacemaker::constraint::base { 'neutron-openvswitch-dhcp-constr' :
      constraint_type => "order",
      first_resource  => "neutron-openvswitch-agent",
      second_resource => "neutron-dhcp-agent",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    quickstack::pacemaker::constraint::colocation { 'neutron-openvswitch-dhcp-colo' :
      source => "neutron-dhcp-agent",
      target => "neutron-openvswitch-agent",
      score  => "INFINITY",
    }
    ->
    quickstack::pacemaker::constraint::base { 'neutron-openvswitch-l3-constr' :
      constraint_type => "order",
      first_resource  => "neutron-openvswitch-agent",
      second_resource => "neutron-l3-agent",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    quickstack::pacemaker::constraint::colocation { 'neutron-openvswitch-l3-colo' :
      source => "neutron-l3-agent",
      target => "neutron-openvswitch-agent",
      score  => "INFINITY",
    }
    ->
    quickstack::pacemaker::constraint::base { 'neutron-openvswitch-metadata-constr' :
      constraint_type => "order",
      first_resource  => "neutron-openvswitch-agent",
      second_resource => "neutron-metadata-agent",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    quickstack::pacemaker::constraint::colocation { 'neutron-openvswitch-metadata-colo' :
      source => "neutron-metadata-agent",
      target => "neutron-openvswitch-agent",
      score  => "INFINITY",
    }
    ->
    quickstack::pacemaker::constraint::colocation { 'neutron-netns-ovs-cleanup-colo' :
      source => "neutron-netns-cleanup",
      target => "neutron-ovs-cleanup",
      score  => "INFINITY",
    }
    ->
    quickstack::pacemaker::constraint::colocation { 'neutron-agents-with-netns-cleanup-colo' :
      source => "neutron-agents",
      target => "neutron-netns-cleanup",
      score  => "INFINITY",
    }
  }
}
