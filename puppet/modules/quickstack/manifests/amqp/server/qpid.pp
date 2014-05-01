class quickstack::amqp::server::qpid (
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

  class {'qpid::server':
    ssl      => str2bool_i("$ssl"),
    freeipa  => str2bool_i("$freeipa"),
    ssl_ca   => $amqp_ca,
    ssl_cert => $amqp_cert,
    ssl_key  => $amqp_key,
    ssl_database_password => $amqp_nssdb_password,
    config_file => $::operatingsystem ? {
        'Fedora' => '/etc/qpid/qpidd.conf',
        default  => '/etc/qpidd.conf',
        },
    auth => $amqp_username ? {
      ''      => 'no',
      default => 'yes',
    },
    clustered => false,
  }

  # quoth the puppet language reference,
  # "Empty strings are false; all other strings are true."
  if $amqp_username {
    qpid_user { $amqp_username:
      password  => $amqp_password,
      file      => '/var/lib/qpidd/qpidd.sasldb',
      realm     => 'QPID',
      provider  => 'saslpasswd2',
      require   => Class['qpid::server'],
    }
  }

}
