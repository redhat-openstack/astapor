#
class quickstack::roles::control::horizon (
) inherits quickstack::roles::params {

  if str2bool_i("$ssl") {
    apache::listen { '443': }

    if str2bool_i("$freeipa") {
      certmonger::request_ipa_cert { 'horizon':
        seclib => "openssl",
        principal => "horizon/${horizon_vip}",
        key => $horizon_key,
        cert => $horizon_cert,
        owner_id => 'apache',
        group_id => 'apache',
        hostname => $horizon_vip,
      }
    } else {
      if $horizon_ca == undef or $horizon_cert == undef or
        $horizon_key == undef {
        fail('The horizon CA, cert and key are all required.')
      }
    }
  }

  package {'python-memcached':
    ensure => installed,
  }~>
  package {'python-netaddr':
    ensure => installed,
    notify => Class['::horizon'],
  }

  file {'/etc/httpd/conf.d/rootredirect.conf':
    ensure  => present,
    content => 'RedirectMatch ^/$ /dashboard/',
    notify  => File['/etc/httpd/conf.d/openstack-dashboard.conf'],
  }

  class {'::horizon':
    secret_key            => $horizon_secret_key,
    keystone_default_role => '_member_',
    keystone_host         => $keystone_vip_private,
    fqdn                  => ["$horizon_vip", "$::fqdn", "$::hostname", 'localhost', '*'],
    listen_ssl            => str2bool_i("$ssl"),
    horizon_cert          => $horizon_cert,
    horizon_key           => $horizon_key,
    horizon_ca            => $horizon_ca,
  }

  class {'memcached':}

  class {'quickstack::firewall::horizon':}

  if ($::selinux != "false"){
    selboolean { 'httpd_can_network_connect':
      value => on,
      persistent => true,
    }
  }
}
