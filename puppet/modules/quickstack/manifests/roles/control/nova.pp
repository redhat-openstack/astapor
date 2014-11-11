#
# == Class: quickstack::roles::nova
#
# Role to configure nova API (controller)
#
#
class quickstack::roles::control::nova (
  $neutron_metadata_proxy_secret = '',
  $public_protocol = 'http',
) inherits quickstack::roles::params {

  class { 'nova::keystone::auth':
    password         => $nova_user_password,
    public_address   => $nova_vip_public,
    public_protocol  => $public_protocol,
    admin_address    => $nova_vip_admin,
    internal_address => $nova_vip_internal,
    region           => $region,
  }

  contain nova::keystone::auth

  class { '::nova::api':
    enabled           => true,
    admin_password    => $nova_user_password,
    auth_host         => $keystone_vip_internal,
    neutron_metadata_proxy_shared_secret => $neutron_metadata_proxy_secret,
  }

  class { [ '::nova::scheduler', '::nova::cert', '::nova::consoleauth', '::nova::conductor' ]:
    enabled => true,
  }

  class { '::nova::vncproxy':
    host    => '0.0.0.0',
    enabled => true,
  }

  class {'quickstack::firewall::nova':}

  # ToDO
  firewall { '001 nova volume incoming':
    proto    => 'tcp',
    dport    => '3260',
    action   => 'accept',
  }

  # ToDO
  firewall { '001 EC2 API incoming':
    proto    => 'tcp',
    dport    => '8773',
    action   => 'accept',
  }
}
