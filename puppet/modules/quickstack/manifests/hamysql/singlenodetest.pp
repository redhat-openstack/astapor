class quickstack::hamysql::singlenodetest (
  # just set up a single node (non-HA) openstack::db::mysql db
  # these params aren't doing anything yet
  $mysql_root_password         = $quickstack::params::mysql_root_password,
  $keystone_db_password        = $quickstack::params::keystone_db_password,
  $glance_db_password          = $quickstack::params::glance_db_password,
  $nova_db_password            = $quickstack::params::nova_db_password,
  $cinder_db_password          = $quickstack::params::cinder_db_password,
  $keystone_db_user            = 'keystone',
  $keystone_db_dbname          = 'keystone',
  $mysql_bind_address         = '0.0.0.0'
) inherits quickstack::params {

  class {'openstack::db::mysql':
      mysql_root_password  => $mysql_root_password,
      keystone_db_password => $keystone_db_password,
      glance_db_password   => $glance_db_password,
      nova_db_password     => $nova_db_password,
      cinder_db_password   => $cinder_db_password,
      neutron_db_password  => '',

      # MySQL
      mysql_bind_address     => '0.0.0.0',
      mysql_account_security => true,

      # Cinder
      cinder                 => false,

      # neutron
      neutron                => false,

      allowed_hosts          => '%',
      enabled                => true,
  }

}
