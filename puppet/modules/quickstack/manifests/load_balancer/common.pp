class quickstack::load_balancer::common {

  class { 'haproxy':
    global_options => {
      'pidfile'    => '/var/run/haproxy.pid',
      'user'       => 'haproxy',
      'group'      => 'haproxy',
      'daemon'     => '',
      'maxconn'    => '10000',
    },
    defaults_options => {
      'mode'         => 'tcp',
      'retries'      => '3',
      'option'       => [ 'tcplog', 'redispatch' ],
      'log'          => '127.0.0.1 local2 warning',
      'timeout'      => [ 'connect 5s', 'client 30s', 'server 60s'],
    },
  }

  haproxy::listen { 'stats':
    ipaddress => '*',
    ports     => '81',
    mode      => 'http',
    options   => {
      'stats' => 'enable',
    },
    collect_exported => false,
  }

  sysctl::value { 'net.ipv4.ip_nonlocal_bind': value => '1' }

  class {'::quickstack::firewall::load_balancer':}
}
