class quickstack::params {
  $verbose                    = 'true'

  $heat_cfn                   = 'false'
  $heat_cloudwatch            = 'false'

  # Passwords are currently changed to decent strings by sed
  # during the setup process. This will move to the Foreman API v2
  # at some point.
  $admin_password             = 'CHANGEME'
  $ceilometer_metering_secret = 'CHANGEME'
  $ceilometer_user_password   = 'CHANGEME'
  $heat_user_password         = 'CHANGEME'
  $heat_db_password           = 'CHANGEME'
  $cinder_db_password         = 'CHANGEME'
  $cinder_user_password       = 'CHANGEME'
  $glance_db_password         = 'CHANGEME'
  $glance_user_password       = 'CHANGEME'
  $horizon_secret_key         = 'CHANGEME'
  $keystone_admin_token       = 'CHANGEME'
  $keystone_db_password       = 'CHANGEME'
  $mysql_root_password        = 'CHANGEME'
  $neutron_db_password        = 'CHANGEME'
  $neutron_user_password      = 'CHANGEME'
  $nova_db_password           = 'CHANGEME'
  $nova_user_password         = 'CHANGEME'

  # Networking
  $private_interface             = 'PRIV_INTERFACE'
  $public_interface              = 'PUB_INTERFACE'
  $fixed_network_range           = 'PRIV_RANGE'
  $floating_network_range        = 'PUB_RANGE'
  $controller_priv_floating_ip   = 'PRIV_IP'
  $controller_pub_floating_ip    = 'PUB_IP'
  $mysql_host                    = 'PRIV_IP'
  $qpid_host                     = 'PRIV_IP'
  $metadata_proxy_shared_secret  = 'CHANGEME'
  $configure_ovswitch            = 'true'

  # Logs
  $admin_email                = "admin@${::domain}"
}
