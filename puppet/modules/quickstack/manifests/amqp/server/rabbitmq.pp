class quickstack::amqp::server::rabbitmq (
  $amqp_server                   = $quickstack::params::amqp_server,
  $amqp_host                     = $quickstack::params::amqp_host,
  $amqp_port                     = $quickstack::params::amqp_port,
  $amqp_username                 = $quickstack::params::amqp_username,
  $amqp_password                 = $quickstack::params::amqp_password,
  $amqp_ca                       = $quickstack::params::amqp_ca,
  $amqp_cert                     = $quickstack::params::amqp_cert,
  $amqp_key                      = $quickstack::params::amqp_key,
  $ssl                           = $quickstack::params::ssl,
  $freeipa                       = $quickstack::params::freeipa,
) inherits quickstack::params {

  # Setting RABBITMQ_NODE_PORT in the ssl case causes duplicate
  # listeners to be defined, and rabbitmq-server will fail to start.
  if str2bool_i("$ssl") {
    $env = {'RABBITMQ_NODE_PORT' => 'UNSET'}
  } else {
    $env = {}
  }

  class {"::rabbitmq":
    environment_variables => $env,
    port                  => $amqp_port,
    ssl                   => str2bool_i("$ssl"),
    ssl_management_port   => $amqp_port,
    ssl_cacert            => $amqp_ca,
    ssl_cert              => $amqp_cert,
    ssl_key               => $amqp_key,
    default_user          => $amqp_username,
    default_pass          => $amqp_password,
    admin_enable          => false,
    package_provider      => "yum",
    package_source        => undef,
  }
}
