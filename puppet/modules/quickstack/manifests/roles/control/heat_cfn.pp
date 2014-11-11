#
class quickstack::roles::control::heat_cfn (
  $heat_cfn_user_password,
  $heat_cfn_vip_public,
  $public_protocol = 'http',
  $heat_cfn_vip_admin,
  $heat_cfn_vip_internal,
) inherits quickstack::roles::params {

  class { 'heat::keystone::auth_cfn':
    password         => $heat_cfn_user_password,
    public_address   => $heat_cfn_vip_public,
    public_protocol  => $public_protocol,
    admin_address    => $heat_cfn_vip_admin,
    internal_address => $heat_cfn_vip_internal,
    region           => $region,
  }

  class { '::heat::api_cfn':
      enabled => 'true',
  }
}
