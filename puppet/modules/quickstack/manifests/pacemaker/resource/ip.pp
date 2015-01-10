define quickstack::pacemaker::resource::ip($ip_address,
                               $cidr_netmask=32,
                               $nic='',
                               $group='',
                               $interval='30s',
                               $monitor_params=undef,
                               $ensure='present') {
  include quickstack::pacemaker::params

  if has_interface_with("ipaddress", map_params("cluster_control_ip")){
    $nic_option = $nic ? {
        ''      => '',
        default => " nic=$nic"
    }
  
    pcmk_resource { "$title-${ip_address}":
      ensure          => $ensure,
      resource_type   => 'IPaddr2',
      resource_params => "ip=${ip_address} cidr_netmask=${cidr_netmask}${nic_option}",
      group           => $group,
      interval        => $interval,
      monitor_params  => $monitor_params,
    }
  }
}
