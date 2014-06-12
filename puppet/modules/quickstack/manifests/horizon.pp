class quickstack::horizon(
    $bind_address          = '0.0.0.0',
    $cache_server_ip       = '127.0.0.1',
    $cache_server_port     = '11211',
    $fqdn                  = $::fqdn,
    $horizon_cert          = undef,
    $horizon_key           = undef,
    $horizon_ca            = undef,
    $keystone_default_role = 'Member',
    $keystone_host         = '127.0.0.1',
    $listen_ssl            = 'false',
    $memcached_servers     = undef,
    $secret_key,
) {

  include ::memcached

  # horizon packages
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

  if str2bool_i("$listen_ssl") {
    apache::listen { '443': }
  }

  # needed for https://bugzilla.redhat.com/show_bug.cgi?id=1111656
  class { 'apache':
    default_vhost => false,
  }

  class {'::horizon':
    bind_address          => $bind_address,
    cache_server_ip       => $cache_server_ip,
    cache_server_port     => $cache_server_port,
    fqdn                  => $fqdn,
    keystone_default_role => $keystone_default_role,
    keystone_host         => $keystone_host,
    horizon_cert          => $horizon_cert,
    horizon_key           => $horizon_key,
    horizon_ca            => $horizon_ca,
    listen_ssl            => str2bool_i("$listen_ssl"),
    secret_key            => $horizon_secret_key,
  }

# Concat::Fragment['Apache ports header'] ->
# File_line['ports_listen_on_bind_address_80']
# TODO: add a file_line to set array of memcached servers
# the above is an example of the required ordering

  if ($::selinux != "false"){
    selboolean { 'httpd_can_network_connect':
      value => on,
      persistent => true,
    }
  }

  class {'::quickstack::firewall::horizon':}
}
