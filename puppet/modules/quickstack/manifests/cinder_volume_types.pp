class quickstack::cinder_volume_types(
  $backend_dell_sc        = false,
  $backend_dell_sc_name   = ['dell_sc'],
  $backend_eqlx           = false,
  $backend_eqlx_name      = ['eqlx'],
  $backend_glusterfs      = false,
  $backend_glusterfs_name = 'glusterfs',
  $backend_iscsi          = false,
  $backend_iscsi_name     = 'iscsi',
  $backend_netapp         = false,
  $backend_netapp_name    = ['netapp'],
  $backend_nfs            = false,
  $backend_nfs_name       = 'nfs',
  $backend_rbd            = false,
  $backend_rbd_name       = 'rbd',

  $os_password,
  $os_tenant_name,
  $os_username,
  $os_auth_url,
  $cinder_api_host,
) {
  Service['openstack-cinder-api'] ->
  exec {'wait-for-cinder-api-being-reachable':
    timeout   => 180,
    tries     => 18,
    try_sleep => 10,
    command   => "/usr/bin/curl http://${cinder_api_host}:8776",
  }

  Cinder::Type {
    os_password     => $os_password,
    os_tenant_name  => $os_tenant_name,
    os_username     => $os_username,
    os_auth_url     => $os_auth_url,
  }

  if str2bool_i($backend_dell_sc) {
    $dell_sc_last_index = size($backend_dell_sc) - 1

    Exec['wait-for-cinder-api-being-reachable'] ->
    quickstack::cinder::multi_instance_type { "dell-sc-${dell_sc_last_index}":
      index           => $dell_sc_last_index,
      resource_prefix => 'dell_sc',
      backend_names   => $backend_dell_sc_name,
    }
  }
  
  if str2bool_i("$backend_eqlx") {
    $eqlx_last_index = size($backend_eqlx_name) - 1

    Exec['wait-for-cinder-api-being-reachable'] ->
    quickstack::cinder::multi_instance_type { "eqlx-${eqlx_last_index}":
      index           => $eqlx_last_index,
      resource_prefix => "eqlx",
      backend_names   => $backend_eqlx_name,
    }
  }

  if str2bool_i("$backend_glusterfs") {
    Exec['wait-for-cinder-api-being-reachable'] ->
    cinder::type { $backend_glusterfs_name:
      set_key   => 'volume_backend_name',
      set_value => $backend_glusterfs_name,
    }
  }

  if str2bool_i("$backend_iscsi") {
    Exec['wait-for-cinder-api-being-reachable'] ->
    cinder::type { $backend_iscsi_name:
      set_key   => 'volume_backend_name',
      set_value => $backend_iscsi_name,
    }
  }

  if str2bool_i("$backend_netapp") {
    $netapp_last_index = size($backend_netapp_name) - 1

    Exec['wait-for-cinder-api-being-reachable'] ->
    quickstack::cinder::multi_instance_type { "netapp-${netapp_last_index}":
      index           => $netapp_last_index,
      resource_prefix => 'netapp',
      backend_names   => $backend_netapp_name,
    }
  }

  if str2bool_i("$backend_nfs") {
    Exec['wait-for-cinder-api-being-reachable'] ->
    cinder::type { $backend_nfs_name:
      set_key   => 'volume_backend_name',
      set_value => $backend_nfs_name,
    }
  }

  if str2bool_i("$backend_rbd") {
    Exec['wait-for-cinder-api-being-reachable'] ->
    cinder::type { $backend_rbd_name:
      set_key   => 'volume_backend_name',
      set_value => $backend_rbd_name,
    }
  }
}
