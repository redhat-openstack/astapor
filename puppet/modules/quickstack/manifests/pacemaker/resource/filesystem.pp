define quickstack::pacemaker::resource::filesystem(
  $ensure         = 'present',
  $device         = undef,
  $directory      = undef,
  $fsoptions      = '',
  $fstype         = undef,
  $group_params   = undef,
  $clone_params   = undef,
) {
  include quickstack::pacemaker::params

  if has_interface_with("ipaddress", map_params("cluster_control_ip")){
    ::pacemaker::resource::filesystem{ "${title}":
    ensure         => $ensure,
    device         => $device,
    directory      => $directory,
    fsoptions      => $fsoptions,
    fstype         => $fstype,
    group_params   => $group_params,
    clone_params   => $clone_params,
    }
  }
}
