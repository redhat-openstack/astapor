class quickstack::pacemaker::nosql (
  $nosql_port              = '27017',
) {

  include quickstack::pacemaker::common

  if (str2bool_i(map_params('include_nosql'))) {
    $pcmk_nosql_group = map_params("nosql_group")
    $_bind_host = map_params("local_bind_addr")
    $_nosql_ips = map_params("lb_backend_server_addrs")
    $nosql_servers = inline_template('<%= @_nosql_ips.map {
       |x| x+":"+@nosql_port }.join(",")%>')
    $nosql_servers_arr = split($nosql_servers,',')

    # TODO: extract this into a helper function
    if ($::pcs_setup_nosql ==  undef or
        !str2bool_i("$::pcs_setup_nosql")) {
      $_enabled = true
      $_ensure = 'running'
    } else {
      $_enabled = false
      $_ensure = undef
    }

    if (str2bool_i(map_params('include_mysql'))) {
      Exec['galera-online'] -> Anchor['nosql cluster start']
    }
    if (str2bool_i(map_params('include_keystone'))) {
      Exec['all-keystone-nodes-are-up'] -> Anchor['nosql cluster start']
    }
    if (str2bool_i(map_params('include_swift'))) {
      Exec['all-swift-nodes-are-up'] -> Anchor['nosql cluster start']
    }
    if (str2bool_i(map_params('include_glance'))) {
      Exec['all-glance-nodes-are-up'] -> Anchor['nosql cluster start']
    }
    if (str2bool_i(map_params('include_nova'))) {
      Exec['all-nova-nodes-are-up'] -> Anchor['nosql cluster start']
    }
    if (str2bool_i(map_params('include_cinder'))) {
      Exec['all-cinder-nodes-are-up'] -> Anchor['nosql cluster start']
    }
    if (str2bool_i(map_params('include_neutron'))) {
      Exec['all-neutron-nodes-are-up'] -> Anchor['nosql cluster start']
    }
    if (str2bool_i(map_params('include_heat'))) {
      Exec['all-heat-nodes-are-up'] -> Anchor['nosql cluster start']
    }
    if (str2bool_i(map_params('include_horizon'))) {
      Exec['all-horizon-nodes-are-up'] -> Anchor['nosql cluster start']
    }

    Class['::quickstack::pacemaker::common']
    ->
    class {'::quickstack::firewall::nosql':
      ports => [$nosql_port],
    } ->
    anchor{'nosql cluster start':} ->
    class { '::quickstack::db::nosql':
      bind_host       => $_bind_host,
      service_enable  => $_enabled,
      service_ensure  => $_ensure,
    } ->
    exec {"pcs-nosql-server-setup":
      command => "/usr/sbin/pcs property set nosql=running --force",
    } ->
    exec {"mongocheck":
      command   => "/usr/bin/mongo ${_bind_host}:${nosql_port}",
      logoutput => false,
      timeout   => 3600,
      tries     => 60,
      try_sleep => 5,
      require   => Service['mongodb'],
    } ->
    exec {"pcs-nosql-server-set-up-on-this-node":
      command => "/tmp/ha-all-in-one-util.bash update_my_node_property nosql"
    } ->
    exec {"all-nosql-nodes-are-up":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/tmp/ha-all-in-one-util.bash all_members_include nosql",
    }

    if has_interface_with("ipaddress", map_params("cluster_control_ip")){
      Exec['all-nosql-nodes-are-up'] ->
      mongodb_replset{'ceilometer':
        members => $nosql_servers_arr,
      }
    }

    Exec['all-nosql-nodes-are-up'] ->

    quickstack::pacemaker::resource::service {'mongod':
      options        => 'start timeout=10s',
      monitor_params => { 'start-delay' => '10s' },
      clone          => true,
    } ->
    anchor {'ha mongo ready':
      require => Quickstack::Pacemaker::Resource::Service['mongod'],
    }
    ->
    Anchor['pacemaker ordering constraints begin']
  }
}
