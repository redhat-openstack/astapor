class quickstack::pacemaker::params (
  $db_vip                    = '',
  $db_group                  = 'db',
  $ceilometer_public_vip     = '',
  $ceilometer_private_vip    = '',
  $ceilometer_admin_vip      = '',
  $ceilometer_group          = 'ceilometer',
  $ceilometer_user_password  = '',
  $ceph_cluster_network      = '',
  $ceph_public_network       = '',
  $ceph_fsid                 = '',
  $ceph_images_key           = '',
  $ceph_volumes_key          = '',
  $ceph_mon_host             = [],
  $ceph_mon_initial_members  = [],
  $ceph_osd_pool_size        = '',
  $ceph_osd_journal_size     = '',
  $cinder_public_vip         = '',
  $cinder_private_vip        = '',
  $cinder_admin_vip          = '',
  $cinder_group              = 'cinder',
  $cinder_db_password        = '',
  $cinder_user_password      = '',
  $cluster_control_ip        = '',
  $glance_public_vip         = '',
  $glance_private_vip        = '',
  $glance_admin_vip          = '',
  $glance_group              = 'glance',
  $glance_db_password        = '',
  $glance_user_password      = '',
  $heat_public_vip           = '',
  $heat_private_vip          = '',
  $heat_admin_vip            = '',
  $heat_group                = 'heat',
  $heat_db_password          = '',
  $heat_user_password        = '',
  $heat_auth_encryption_key  = '',
  $heat_cfn_enabled          = 'true',
  $heat_cfn_public_vip       = '',
  $heat_cfn_private_vip      = '',
  $heat_cfn_admin_vip        = '',
  $heat_cfn_group            = 'heat_cfn',
  $heat_cfn_user_password    = '',
  $heat_cloudwatch_enabled   = 'true',
  $horizon_public_vip        = '',
  $horizon_private_vip       = '',
  $horizon_admin_vip         = '',
  $horizon_group             = 'horizon',
  $include_ceilometer        = 'true',
  $include_cinder            = 'true',
  $include_glance            = 'true',
  $include_heat              = 'true',
  $include_horizon           = 'true',
  $include_keystone          = 'true',
  $include_mysql             = 'true',
  $include_neutron           = 'true',
  $include_nosql             = 'true',
  $include_nova              = 'true',
  $include_amqp              = 'true',
  $include_swift             = 'true',
  $loadbalancer_vip          = '',
  $loadbalancer_group        = 'loadbalancer',
  $lb_backend_server_names   = [],
  $lb_backend_server_addrs   = [],
  $pcmk_server_names         = [],
  $pcmk_server_addrs         = [],
  $keystone_public_vip       = '',
  $keystone_private_vip      = '',
  $keystone_admin_vip        = '',
  $keystone_group            = 'keystone',
  $keystone_db_password      = '',
  $keystone_user_password    = '',
  $neutron                   = 'false',
  $neutron_metadata_proxy_secret,
  $neutron_public_vip        = '',
  $neutron_private_vip       = '',
  $neutron_admin_vip         = '',
  $neutron_group             = 'neutron',
  $neutron_db_password       = '',
  $neutron_user_password     = '',
  $nosql_vip                 = '',
  $nosql_group               = 'nosql',
  $nova_public_vip           = '',
  $nova_private_vip          = '',
  $nova_admin_vip            = '',
  $nova_group                = 'nova',
  $nova_db_password          = '',
  $nova_user_password        = '',
  $pcmk_ip                   = '',
  $pcmk_iface                = '',
  $pcmk_network              = '',
  $private_ip                = '',
  $private_iface             = '',
  $private_network           = '',
  $amqp_provider             = 'rabbitmq',
  $amqp_port                 = '5672',
  $amqp_vip                  = '',
  $amqp_group                = 'amqp',
  $amqp_username             = '',
  $amqp_password             = '',
  $swift_public_vip          = '',
  $swift_user_password       = '',
  $swift_group               = 'swift',
) {
  $local_bind_addr = find_ip("$private_network",
                            "$private_iface",
                            "$private_ip")
  $pcmk_bind_addr = find_ip("$pcmk_network",
                            "$pcmk_iface",
                            "$pcmk_ip")

  include quickstack::pacemaker::common
  include quickstack::pacemaker::load_balancer
  include quickstack::pacemaker::galera
  include quickstack::pacemaker::qpid
  include quickstack::pacemaker::keystone
  include quickstack::pacemaker::swift
  include quickstack::pacemaker::glance
  include quickstack::pacemaker::nova
  include quickstack::pacemaker::cinder
  include quickstack::pacemaker::heat
  include quickstack::pacemaker::constraints

  Class['::quickstack::pacemaker::common'] ->
  Class['::quickstack::pacemaker::load_balancer'] ->
  Class['::quickstack::pacemaker::galera'] ->
  Class['::quickstack::pacemaker::qpid'] ->
  Class['::quickstack::pacemaker::keystone'] ->
  Class['::quickstack::pacemaker::swift'] ->
  Class['::quickstack::pacemaker::glance'] ->
  Class['::quickstack::pacemaker::nova'] ->
  Class['::quickstack::pacemaker::cinder'] ->
  Class['::quickstack::pacemaker::heat'] ->
  Class['::quickstack::pacemaker::constraints']

}
