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
) {

  if has_interface_with("ipaddress", map_params("cluster_control_ip")) {
    $setup_cluster = true
  } else {
    $setup_cluster = false
  }

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

  Class['pacemaker::corosync'] ->
  exec { 'stonith-setup-complete': command => '/bin/true'}

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
  }
}
