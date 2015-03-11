define quickstack::pacemaker::resource::galera( $timeout       = '300s',
                                                $gcomm_addrs   = [],
                                                $limit_no_file = '16384',
) {
  include quickstack::pacemaker::params

  if has_interface_with("ipaddress", map_params("cluster_control_ip")){

    $num_nodes = size($gcomm_addrs)
    $gcomm_addresses = inline_template('gcomm://<%= @gcomm_addrs.join "," %>')

    # once pcs verson >= 0.9.116 is available, we can simplify the below command to be a single
    # call to pcs without the "-f"
    $create_cmd = "/usr/sbin/pcs cluster cib /tmp/galera-ra && /usr/sbin/pcs -f /tmp/galera-ra resource create galera galera additional_parameters='--open-files-limit=${limit_no_file}' enable_creation=true wsrep_cluster_address=\"$gcomm_addresses\" op promote timeout=300s on-fail=block --master meta master-max=3 ordered=true && /usr/sbin/pcs cluster cib-push /tmp/galera-ra"

    anchor { "qprs start galera": }
    ->
    # probably want to move this to puppet-pacemaker eventually
    exec {"create galera resource":
      command   => $create_cmd,
      tries     => 4,
      try_sleep => 30,
      unless    => '/usr/sbin/pcs resource show galera',
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
