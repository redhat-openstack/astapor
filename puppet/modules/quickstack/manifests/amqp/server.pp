class quickstack::amqp::server (
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

  if $amqp_server == 'qpid' {
    $klass = 'qpid'
  } else {
    $klass = 'rabbitmq'
  }

  class { "quickstack::amqp::server::${klass}":
    amqp_server   => $amqp_server,
    amqp_host     => $amqp_host,
    amqp_port     => $amqp_port,
    amqp_username => $amqp_username,
    amqp_password => $amqp_password,
    amqp_ca       => $amqp_ca,
    amqp_cert     => $amqp_cert,
    amqp_key      => $amqp_key,
    ssl           => $ssl,
    freeipa       => $freeipa,
  }

}
