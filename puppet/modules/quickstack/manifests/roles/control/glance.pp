#
class quickstack::roles::control::glance (
  $glance_backend  = 'file',
  $public_protocol = 'http',
  $verbose         = 'false',
) inherits quickstack::roles::params {

  $amqp_port= amqp_port(str2bool_i("$ssl"))

  class { 'glance::keystone::auth':
    password         => $glance_user_password,
    public_address   => $glance_vip_public,
    public_protocol  => $public_protocol,
    admin_address    => $glance_vip_admin,
    internal_address => $glance_vip_internal,
    region           => $region,
  }

  contain glance::keystone::auth

  class {'quickstack::glance':
    db_host        => $mysql_vip,
    db_ssl         => str2bool_i("$ssl"),
    db_ssl_ca      => $mysql_ca,
    user_password  => $glance_user_password,
    db_password    => $glance_db_password,
    backend        => $glance_backend,
    rbd_store_user => $glance_rbd_store_user,
    rbd_store_pool => $glance_rbd_store_pool,
    require        => Class['quickstack::db::mysql'],
    amqp_host      => $amqp_vip,
    amqp_port      => $amqp_port,
    amqp_username  => $amqp_username,
    amqp_password  => $amqp_password,
    amqp_provider  => $amqp_provider,
    verbose        => $verbose,
  }
}
