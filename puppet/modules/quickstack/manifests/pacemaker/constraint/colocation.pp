define quickstack::pacemaker::constraint::colocation ($source,
                                          $target,
                                          $score='INFINITY',
                                          $ensure=present) {
  include quickstack::pacemaker::params

  if has_interface_with("ipaddress", map_params("cluster_control_ip")){  
    ::pacemaker::constraint::colocation{ "$name":
                                          source => $source,
                                          target => $target,
                                          score  => $score,
                                          ensure => $ensure}
  }
}

