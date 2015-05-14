define quickstack::pacemaker::resource::ip(
  $ensure       = 'present',
  $ip_address   = undef,
  $cidr_netmask = 32,
  $nic          = '',
  $group_params = undef,
) {
  include quickstack::pacemaker::params

  if has_interface_with('ipaddress', map_params('cluster_control_ip')){
    $nic_option = $nic ? {
        ''      => '',
        default => " nic=${nic}"
    }

    pcmk_resource { "${title}-${ip_address}":
      ensure          => $ensure,
      resource_type   => 'IPaddr2',
      resource_params => "ip=${ip_address} cidr_netmask=${cidr_netmask}${nic_option}",
      group_params    => $group_params,
    }
  }
}
