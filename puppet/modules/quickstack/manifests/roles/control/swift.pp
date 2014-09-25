#
class quickstack::roles::control::swift (

) inherits quickstack::roles::params {
  class { 'swift::keystone::auth':
    password         => $swift_user_password,
    public_address   => $swift_vip_public,
    public_protocol  => $public_protocol,
    admin_address    => $swift_vip_admin,
    internal_address => $swift_vip_internal,
    region           => $region,
  }

  contain swift::keystone::auth

  class {'quickstack::swift::proxy':
    swift_proxy_host           => $swift_vip_public,
    keystone_host              => $keystone_vip_public,
    swift_admin_password       => $swift_admin_password,
    swift_shared_secret        => $swift_shared_secret,
    swift_storage_ips          => $swift_storage_ips,
    swift_storage_device       => $swift_storage_device,
    swift_ringserver_ip        => $swift_ringserver_ip,
    swift_is_ringserver        => true,
  }

  class {'quickstack::firewall::swift':}
}
