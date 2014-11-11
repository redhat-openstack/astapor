#
class quickstack::roles::neutron::agents::metadata (
) inherits quickstack::roles::params {

  class { '::neutron::agents::metadata':
    auth_password  => $neutron_user_password,
    auth_url       => "http://${keystone_vip_private}:35357/v2.0",
    enabled        => 'true',
    manage_service => 'true',
    metadata_ip    => $neutron_vip_public,
    shared_secret  => $neutron_metadata_proxy_secret,
  }
}
