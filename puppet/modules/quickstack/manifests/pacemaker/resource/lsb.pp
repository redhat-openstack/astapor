define quickstack::pacemaker::resource::lsb($group='',
                                            $clone=false,
                                            $interval='30s',
                                            $ensure='present') {
  include quickstack::pacemaker::params

  if has_interface_with("ipaddress", map_params("cluster_control_ip")){  
    ::pacemaker::resource::lsb{ "$name":
                                group    => $group,
                                clone    => $clone,
                                interval => $interval,
                                ensure   => $endure}
  }
}
