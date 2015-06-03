define quickstack::pacemaker::resource::galera( $timeout       = '300s',
                                                $gcomm_addrs   = [],
                                                $limit_no_file = '16384',
) {
  include quickstack::pacemaker::params

  if has_interface_with("ipaddress", map_params("cluster_control_ip")){

    $num_nodes = size($gcomm_addrs)
    $gcomm_addresses = inline_template('gcomm://<%= @gcomm_addrs.join "," %>')

    anchor { "qprs start galera": }
    ->
    pcmk_resource { 'galera':
      resource_type      => 'galera',
      resource_params    => "additional_parameters='--open-files-limit=${limit_no_file}' enable_creation=true wsrep_cluster_address=\"${gcomm_addresses}\"",
      meta_params        => 'master-max=3 ordered=true',
      op_params          => "promote timeout=300s on-fail=block",
      master_params      => '',
      post_success_sleep => 5,
      tries              => 4,
      try_sleep          => 30,
    }
    ->
    exec {"wait for galera resource":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/usr/sbin/pcs resource show galera",
    }
    -> anchor { "qprs end galera": }
  }
}
