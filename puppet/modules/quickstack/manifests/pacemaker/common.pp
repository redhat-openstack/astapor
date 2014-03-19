class quickstack::pacemaker::common (
  $pacemaker_cluster_name         = $quickstack::params::pacemaker_cluster_name,
  $pacemaker_cluster_members      = $quickstack::params::pacemaker_cluster_members,
  # fencing_type should be either "disabled", "fence_xvm", or "". ""
  #   means do not disable stonith, but also don't add any fencing
  $fencing_type                   = $quickstack::params::fencing_type,
  $fence_ipmilan_address          = $quickstack::params::fence_ipmilan_address,
  $fence_ipmilan_username         = $quickstack::params::fence_ipmilan_username,
  $fence_ipmilan_password         = $quickstack::params::fence_ipmilan_password,
  $fence_ipmilan_interval         = $quickstack::params::fence_ipmilan_interval,
  $fence_xvm_clu_iface            = $quickstack::params::fence_xvm_clu_iface,
  $fence_xvm_manage_key_file      = $quickstack::params::fence_xvm_manage_key_file,
  $fence_xvm_key_file_password    = $quickstack::params::fence_xvm_key_file_password,

) inherits quickstack::params {
  class {'pacemaker::corosync':
    cluster_name    => $pacemaker_cluster_name,
    cluster_members => $pacemaker_cluster_members,
  }

  if $fencing_type =~ /(?i-mx:^disabled$)/ {
    class {'pacemaker::stonith':
      disable => true }
    Class['pacemaker::corosync'] -> Class['pacemaker::stonith']
  }
  elsif $fencing_type =~ /(?i-mx:^ipmilan$)/ {
    class {'pacemaker::stonith':
      disable => false }
    class {'pacemaker::stonith::ipmilan':
      address        => $fence_ipmilan_address,
      username       => $fence_ipmilan_username,
      password       => $fence_ipmilan_password,
      interval       => $fence_ipmilan_interval,
      pcmk_host_list => $pacemaker_cluster_members,
    }
    Class['pacemaker::corosync'] -> Class['pacemaker::stonith'] ->
    Class['pacemaker::stonith::ipmilan']
  }
  elsif $fencing_type =~ /(?i-mx:^fence_xvm$)/ {
    $clu_ip_address = getvar(regsubst("ipaddress_$fence_xvm_clu_iface", '[.-]', '_', 'G'))
    class {'pacemaker::stonith':
      disable => false }
    class {'pacemaker::stonith::fence_xvm':
      name              => "$::hostname",
      manage_key_file   => str2bool_i("$fence_xvm_manage_key_file"),
      key_file_password => $fence_xvm_key_file_password,
      port              => "$::hostname",    # the name of the vm
      pcmk_host         => $clu_ip_address,  # the hostname or IP that pacemaker uses
    }
    Class['pacemaker::corosync'] -> Class['pacemaker::stonith'] ->
    Class['pacemaker::stonith::fence_xvm']
  }
}
