class quickstack::pacemaker::network (
) inherits quickstack::pacemaker::params {

  include quickstack::pacemaker::common

  Class['::quickstack::pacemaker::common'] ->
  Class['::quickstack::pacemaker::network']

  if (str2bool_i($include_neutron)) {
    $ovs_nic = find_nic("$ovs_tunnel_network","$ovs_tunnel_iface","")

    if (str2bool_i($include_mysql)) {
      Exec['galera-online'] -> Exec['i-am-neutron-vip-OR-neutron-is-up-on-vip']
    }
    if (str2bool_i($include_keystone)) {
      Exec['all-keystone-nodes-are-up'] -> Exec['i-am-neutron-vip-OR-neutron-is-up-on-vip']
    }
    if (str2bool_i($include_swift)) {
      Exec['all-swift-nodes-are-up'] -> Exec['i-am-neutron-vip-OR-neutron-is-up-on-vip']
    }
    if (str2bool_i($include_cinder)) {
      Exec['all-cinder-nodes-are-up'] -> Exec['i-am-neutron-vip-OR-neutron-is-up-on-vip']
    }
    if (str2bool_i($include_glance)) {
      Exec['all-glance-nodes-are-up'] -> Exec['i-am-neutron-vip-OR-neutron-is-up-on-vip']
    }
    if (str2bool_i($include_nova)) {
      Exec['all-nova-nodes-are-up'] -> Exec['i-am-neutron-vip-OR-neutron-is-up-on-vip']
    }
    Exec['i-am-neutron-vip-OR-neutron-is-up-on-vip'] ->
#    Class[neutron::server::notifications] ->
    Exec['pcs-neutron-server-set-up']

    class {"::quickstack::load_balancer::neutron":
      frontend_pub_host    => $neutron_public_vip,
      frontend_priv_host    => $neutron_private_vip,
      frontend_admin_host    => $neutron_admin_vip,
      backend_server_names => $lb_backend_server_names,
      backend_server_addrs => $lb_backend_server_addrs,
    }

    Class['::quickstack::pacemaker::common']
    ->
    quickstack::pacemaker::vips { "$neutron_group":
      public_vip  => $neutron_public_vip,
      private_vip => $neutron_private_vip,
      admin_vip   => $neutron_admin_vip,
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
    class { 'quickstack::network::server':
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
      first_resource  => "neutron-ovs-cleanup-clone",
      second_resource => "neutron-netns-cleanup-clone",
      first_action    => "start",
      second_action   => "start",
    }
    ->
    quickstack::pacemaker::constraint::base { 'neutron-cleanup-to-agents-constr' :
      constraint_type => "order",
      first_resource  => "neutron-netns-cleanup-clone",
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
  }
}
