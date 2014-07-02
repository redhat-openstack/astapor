# == Class: quickstack::pacemaker::common
#
# A base class to configure your pacemaker cluster
#
# === Parameters
#
# [*pacemaker_cluster_name*]
#   The name of your openstack cluster
# [*pacemaker_cluster_members*]
#   An array of IPs for the nodes in your cluster
# [*fencing_type*]
#   Should be either "disabled", "fence_xvm", "ipmilan", or "". ""
#   means do not disable stonith, but also don't add any fencing
# [*fence_ipmilan_address*]
#
# [*fence_ipmilan_username*]
#
# [*fence_ipmilan_password*]
#
# [*fence_ipmilan_interval*]
#
# [*fence_xvm_clu_iface*]
#
# [*fence_xvm_clu_network*]
#
# [*fence_xvm_manage_key_file*]
#
# [*fence_xvm_key_file_password*]
#

class quickstack::pacemaker::common (
  $pacemaker_cluster_name         = "openstack",
  $pacemaker_cluster_members      = "192.168.200.10 192.168.200.11 192.168.200.12",
  $fencing_type                   = "disabled",
  $fence_ipmilan_address          = "",
  $fence_ipmilan_username         = "",
  $fence_ipmilan_password         = "",
  $fence_ipmilan_interval         = "60s",
  $fence_ipmilan_hostlist         = "",
  $fence_ipmilan_host_to_address  = [],
  $fence_ipmilan_expose_lanplus   = "true",
  $fence_ipmilan_lanplus_options  = "",
  $fence_xvm_clu_iface            = "eth2",
  $fence_xvm_clu_network          = "",
  $fence_xvm_manage_key_file      = "false",
  $fence_xvm_key_file_password    = "",
) {
  include quickstack::pacemaker::params

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
  if has_interface_with("ipaddress", map_params("cluster_control_ip")) {
=======
  if (map_params("cluster_control_ip") == map_params("local_bind_addr")) {
>>>>>>> sync with redhat/astapor-master
=======
  if has_interface_with("ipaddress", map_params("cluster_control_ip")) {
>>>>>>> syncing with redhat repo
    $setup_cluster = true
  } else {
    $setup_cluster = false
  }

<<<<<<< HEAD
=======
>>>>>>> Updating astapor for ICE HOUSE
=======
>>>>>>> sync with redhat/astapor-master
  package {'rpcbind': } ->
  service {'rpcbind':
    enable => true,
    ensure => 'running',
  } ->
  class {'pacemaker::corosync':
    cluster_name    => $pacemaker_cluster_name,
    cluster_members => $pacemaker_cluster_members,
    setup_cluster   => $setup_cluster,
  }

  if $fencing_type =~ /(?i-mx:^disabled$)/ {
    $fencing = false
    class {'pacemaker::stonith':
      disable => true,
    }
    Class['pacemaker::corosync'] -> Class['pacemaker::stonith']
  }
  elsif $fencing_type =~ /(?i-mx:^fence_ipmilan$)/ {
    $fencing = true
    class {'pacemaker::stonith':
      disable => false,
    }
    class {'quickstack::pacemaker::stonith::ipmilan':
      address         => $fence_ipmilan_address,
      username        => $fence_ipmilan_username,
      password        => $fence_ipmilan_password,
      interval        => $fence_ipmilan_interval,
      pcmk_host_list  => $fence_ipmilan_hostlist,
      host_to_address => $fence_ipmilan_host_to_address,
      lanplus         => str2bool_i("$fence_ipmilan_expose_lanplus"),
      lanplus_options => $fence_ipmilan_lanplus_options,
    }
  }
  elsif $fencing_type =~ /(?i-mx:^fence_xvm$)/ {
    $fencing = true
    $clu_ip_address = find_ip("$fence_xvm_clu_network",
                              "$fence_xvm_clu_iface",
                              "")
    class {'pacemaker::stonith':
      disable => false,
    }
    class {'pacemaker::stonith::fence_xvm':
      name              => "$::hostname",
      manage_key_file   => str2bool_i("$fence_xvm_manage_key_file"),
      key_file_password => $fence_xvm_key_file_password,
      port              => "$::hostname",    # the name of the vm
    }
  }
  else {
    $fencing = false
    notify{"Unexpected value for parameter fencing_type: $fencing_type:.  Expect one of disabled, fence_ipmilan, or fence_xvm":
      loglevel => alert,
    }
  }
  Class['pacemaker::corosync'] ->
  exec { 'stonith-setup-complete': command => '/bin/true'}

  if $fencing {
    exec { "all-nodes-joined-cluster":
      # wait for all nodes to join the cluster, rather just the number
      # required for quorum.  e.g., in a three node cluster, wait for
      # all three nodes to join rather than proceeding after quorum is
      # acheived after only two nodes joining.  this is so that
      # fencing doesn't prematurely fence a node that hasn't joined
      # cluster yet.
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      path => '/usr/bin:/usr/sbin:/bin',
      command => 'crm_mon --as-xml 2>&1 | grep -e "<node .*online=\"false\"" -e "<node .*pending=\"true\"" -e "<node .*unclean=\"true\"" -e "[C|c]onnection refused" >/dev/null 2>&1; test "$?" == "1"',
    }
    Class['pacemaker::corosync'] -> Exec['all-nodes-joined-cluster'] ->
    Class['pacemaker::stonith']
    if ($fencing_type == "fence_ipmilan") {
      Class['pacemaker::stonith'] -> Class['quickstack::pacemaker::stonith::ipmilan'] -> Exec['stonith-setup-complete']
    }
    elsif ($fencing_type == "fence_xvm") {
      Class['pacemaker::stonith'] -> Class['pacemaker::stonith::fence_xvm'] -> Exec['stonith-setup-complete']
    }
  }

  file { "ha-all-in-one-util-bash-tests":
    path    => "/tmp/ha-all-in-one-util.bash",
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('quickstack/ha-all-in-one-util.erb'),
  }

  if has_interface_with("ipaddress", map_params("cluster_control_ip")){
    Exec['stonith-setup-complete']
    ->
    exec {"pcs-resource-default":
      command => "/usr/sbin/pcs resource defaults resource-stickiness=100",
    }
    ->
    exec {"pcs-property-start-failure-is-false":
      command => "/usr/sbin/pcs property set start-failure-is-fatal=false",
    }
  }
}
