#
class quickstack::roles::support::mysql (
  $bind_address = '0.0.0.0',
) inherits quickstack::roles::params {

  if str2bool_i("$ssl") {
    if str2bool_i("$freeipa") {
      certmonger::request_ipa_cert { 'mysql':
        seclib    => "openssl",
        principal => "mysql/${mysql_vip}",
        key       => $mysql_key,
        cert      => $mysql_cert,
        owner_id  => 'mysql',
        group_id  => 'mysql',
      }
    } else {
      if $mysql_ca == undef or $mysql_cert == undef or $mysql_key == undef {
        fail('The mysql CA, cert and key are all required.')
      }
    }
  }

  class {'quickstack::db::mysql':
    mysql_root_password  => $mysql_root_password,
    keystone_db_password => $keystone_db_password,
    glance_db_password   => $glance_db_password,
    nova_db_password     => $nova_db_password,
    cinder_db_password   => $cinder_db_password,
    neutron_db_password  => $neutron_db_password,

    # MySQL
    mysql_bind_address     => $mysql_bind_address,
    mysql_account_security => true,
    mysql_ssl              => str2bool_i("$ssl"),
    mysql_ca               => $mysql_ca,
    mysql_cert             => $mysql_cert,
    mysql_key              => $mysql_key,

    allowed_hosts          => ['%',$mysql_vip],
    enabled                => true,

    # Networking
    neutron                => str2bool_i("$neutron"),
  }

  # TODO:
  firewall { '001 mysql incoming':
    proto    => 'tcp',
    dport    => '3306',
    action   => 'accept',
  }
}
