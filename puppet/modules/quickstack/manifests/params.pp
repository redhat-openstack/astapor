class quickstack::params {
  # Logs
  $admin_email                = "admin@${::domain}"
  $verbose                    = 'true'

  # Passwords are currently changed to decent strings by sed
  # during the setup process. This will move to the Foreman API v2
  # at some point.
  $admin_password             = 'CHANGEME'
  $ceilometer_metering_secret = 'CHANGEME'
  $ceilometer_user_password   = 'CHANGEME'
  $heat_user_password         = 'CHANGEME'
  $heat_db_password           = 'CHANGEME'
  $horizon_secret_key         = 'CHANGEME'
  $keystone_admin_token       = 'CHANGEME'
  $keystone_db_password       = 'CHANGEME'
  $mysql_root_password        = 'CHANGEME'
  $neutron_db_password        = 'CHANGEME'
  $neutron_user_password      = 'CHANGEME'
  $nova_db_password           = 'CHANGEME'
  $nova_user_password         = 'CHANGEME'

  # Networking - Common
  $private_interface             = 'PRIV_INTERFACE'
  $public_interface              = 'PUB_INTERFACE'
  $controller_priv_floating_ip   = 'PRIV_IP'
  $controller_pub_floating_ip    = 'PUB_IP'

  # Nova-network specific
  $fixed_network_range           = 'PRIV_RANGE'
  $floating_network_range        = 'PUB_RANGE'

  # Neutron specific
  $metadata_proxy_shared_secret  = 'CHANGEME'
  # Floating IPs - Seeds needed
  $public_network_name           = 'public'
  $public_cidr                   = 'CHANGEME'
  $public_gateway_ip             = 'CHANGEME'
  $public_allocation_pools_start = 'CHANGEME'
  $public_allocation_pools_end   = 'CHANGEME'

  # Cinder
  $cinder_db_password           = 'CHANGEME'
  $cinder_user_password         = 'CHANGEME'
  # Cinder backend - Several backends should be able to coexist
  $cinder_backend_gluster       = true
  $cinder_backend_iscsi         = false
  # Cinder gluster
  $cinder_gluster_path          = '/srv/gluster/cinder'
  $cinder_gluster_peers         = [ '192.168.0.2', '192.168.0.3', '192.168.0.4' ]
  $cinder_gluster_replica_count = '3'

  # Glance
  $glance_db_password           = 'CHANGEME'
  $glance_user_password         = 'CHANGEME'
  # Glance_Gluster
  $glance_gluster_path          = '/srv/gluster/glance'
  $glance_gluster_peers         = [ '192.168.0.2', '192.168.0.3', '192.168.0.4' ]
  $glance_gluster_replica_count = '3'
}
