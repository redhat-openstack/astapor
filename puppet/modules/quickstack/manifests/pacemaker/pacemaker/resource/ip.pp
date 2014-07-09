define quickstack::pacemaker::resource::ip($ip_address,
                               $cidr_netmask=32,
                               $nic='',
                               $group='',
                               $interval='30s',
                               $monitor_params=undef,
                               $ensure='present') {
  include quickstack::pacemaker::params

  if has_interface_with("ipaddress", map_params("cluster_control_ip")){
    ::pacemaker::resource::ip{ "$name": 
                            ip_address     => $ip_address,
                            cidr_netmask   => $cidr_netmask,
                            nic            => $nic,
                            group          => $group,
                            interval       => $interval,
                            monitor_params => $monitor_params,
                            ensure         => $ensure }
  }
}
