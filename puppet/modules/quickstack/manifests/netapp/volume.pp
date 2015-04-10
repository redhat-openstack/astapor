define quickstack::netapp::volume (
  $index,
  $backend_netapp_name_array,
  $netapp_hostname_array,
  $netapp_login_array,
  $netapp_password_array,
  $netapp_server_port_array,
  $netapp_storage_family_array,
  $netapp_transport_type_array,
  $netapp_storage_protocol_array,
  $netapp_nfs_shares_array,
  $netapp_nfs_shares_config_array,
  $netapp_volume_list_array,
  $netapp_vfiler_array,
  $netapp_vserver_array,
  $netapp_controller_ips_array,
  $netapp_sa_password_array,
  $netapp_storage_pools_array
  ) {

  if($index >= 0)
  {
    $backend_netapp_name      = $backend_netapp_name_array[$index]
    $netapp_hostname          = $netapp_hostname_array[$index]
    $netapp_login             = $netapp_login_array[$index]
    $netapp_password          = $netapp_password_array[$index]
    $netapp_server_port       = $netapp_server_port_array[$index]
    $netapp_storage_family    = $netapp_storage_family_array[$index]
    $netapp_transport_type    = $netapp_transport_type_array[$index]
    $netapp_storage_protocol  = $netapp_storage_protocol_array[$index]
    $netapp_nfs_shares        = $netapp_nfs_shares_array[$index]
    $netapp_nfs_shares_config = $netapp_nfs_shares_config_array[$index]
    $netapp_volume_list       = $netapp_volume_list_array[$index]
    $netapp_vfiler            = $netapp_vfiler_array[$index]
    $netapp_vserver           = $netapp_vserver_array[$index]
    $netapp_controller_ips    = $netapp_controller_ips_array[$index]
    $netapp_sa_password       = $netapp_sa_password_array[$index]
    $netapp_storage_pools     = $netapp_storage_pools_array[$index]

    # If NetApp nfs_shares parameter is empty ([]), set to undef.
    # Otherwise, it will be interpreted as a real value and interfere with
    # a non-NFS deployment
    if ($netapp_nfs_shares == []){
      $_netapp_nfs_shares_sanitized = undef
    }
    else {
      $_netapp_nfs_shares_sanitized = split($netapp_nfs_shares, ',')
    }

    cinder::backend::netapp { $backend_netapp_name:
      netapp_server_hostname    => $netapp_hostname,
      netapp_login              => $netapp_login,
      netapp_password           => $netapp_password,
      netapp_server_port        => $netapp_server_port,
      netapp_storage_family     => $netapp_storage_family,
      netapp_transport_type     => $netapp_transport_type,
      netapp_storage_protocol   => $netapp_storage_protocol,
      nfs_shares                => $_netapp_nfs_shares_sanitized,
      nfs_shares_config         => $netapp_nfs_shares_config,
      netapp_volume_list        => $netapp_volume_list,
      netapp_vfiler             => $netapp_vfiler,
      netapp_vserver            => $netapp_vserver,
      netapp_controller_ips     => $netapp_controller_ips,
      netapp_sa_password        => $netapp_sa_password,
      netapp_storage_pools      => $netapp_storage_pools,
    }

    #recurse
    $next = $index -1
    quickstack::netapp::volume {$next:
      index => $next,
      backend_netapp_name_array       => $backend_netapp_name_array,
      netapp_hostname_array           => $netapp_hostname_array,
      netapp_login_array              => $netapp_login_array,
      netapp_password_array           => $netapp_password_array,
      netapp_server_port_array        => $netapp_server_port_array,
      netapp_storage_family_array     => $netapp_storage_family_array,
      netapp_transport_type_array     => $netapp_transport_type_array,
      netapp_storage_protocol_array   => $netapp_storage_protocol_array,
      netapp_nfs_shares_array         => $netapp_nfs_shares_array,
      netapp_nfs_shares_config_array  => $netapp_nfs_shares_config_array,
      netapp_volume_list_array        => $netapp_volume_list_array,
      netapp_vfiler_array             => $netapp_vfiler_array,
      netapp_vserver_array            => $netapp_vserver_array,
      netapp_controller_ips_array     => $netapp_controller_ips_array,
      netapp_sa_password_array        => $netapp_sa_password_array,
      netapp_storage_pools_array      => $netapp_storage_pools_array,
   }
  }
}
