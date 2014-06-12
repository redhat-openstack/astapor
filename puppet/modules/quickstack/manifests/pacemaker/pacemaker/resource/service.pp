define quickstack::pacemaker::resource::service($group='',
                                                $clone=false,
                                                $interval='30s',
                                                $monitor_params=undef,
                                                $ensure='present',
                                                $options='') {
  include quickstack::pacemaker::params

  if has_interface_with("ipaddress", map_params("cluster_control_ip")){
    ::pacemaker::resource::service{ "$name":
                                group          => $group,
                                clone          => $clone,
                                interval       => $interval,
                                monitor_params => $monitor_params,
                                ensure         => $ensure,
                                options        => $options}
  }
}
