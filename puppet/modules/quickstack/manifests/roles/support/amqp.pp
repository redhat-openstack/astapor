#
class quickstack::roles::support::amqp ()
  inherits quickstack::roles::params {

  $amqp_port     = amqp_port(str2bool_i("$ssl"))
  $qpid_protocol = qpid_protocol(str2bool_i("$ssl"))

  if str2bool_i("$ssl") {
    if str2bool_i("$freeipa") {
      if $amqp_provider == 'rabbitmq' {
        certmonger::request_ipa_cert { 'amqp':
          seclib    => "openssl",
          principal => "amqp/${amqp_vip}",
          key       => $amqp_key,
          cert      => $amqp_cert,
          owner_id  => 'rabbitmq',
          group_id  => 'rabbitmq',
        }
      }
    } else {
      if $amqp_ca == undef or $amqp_cert == undef or $amqp_key == undef {
        fail('The amqp CA, cert and key are all required.')
      }
    }
  }

  class {'quickstack::amqp::server':
    amqp_provider => $amqp_provider,
    amqp_host     => $amqp_vip,
    amqp_port     => $amqp_port,
    amqp_username => $amqp_username,
    amqp_password => $amqp_password,
    amqp_ca       => $amqp_ca,
    amqp_cert     => $amqp_cert,
    amqp_key      => $amqp_key,
    ssl           => $ssl,
    freeipa       => $freeipa,
  }

  # TODO: Need to fix quickstack::firewall::amqp
  firewall { '001 amqp incoming':
    proto    => 'tcp',
    dport    => "$amqp_port",
    action   => 'accept',
  }
}
