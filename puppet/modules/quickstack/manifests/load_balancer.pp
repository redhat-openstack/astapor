class quickstack::load_balancer (
  $lb_private_vip,
  $lb_public_vip,
  $lb_member_names,
  $lb_member_addrs,
) inherits quickstack::params {

  class { 'haproxy':
    global_options => {
      'log'     => '/dev/log local0',
      'pidfile' => '/var/run/haproxy.pid',
      'user'    => 'haproxy',
      'group'   => 'haproxy',
      'daemon'  => '',
      'maxconn' => '4000',
    },
    defaults_options => {
      'mode'    => 'http',
      'log'     => 'global',
      'retries' => '3',
      'option'  => [ 'httplog', 'redispatch' ],
      'timeout' => [ 'connect 10s', 'client 1m', 'server 1m' ],
    },
  }

  haproxy::listen { 'stats':
    ipaddress => '*',
    ports     => '80',
    mode      => 'http',
    options   => {
      'stats' => 'enable',
    },
    collect_exported => false,
  }
  
  quickstack::load_balancer::proxy { 'cinder': port => '8776' }
  quickstack::load_balancer::proxy { 'glance': port => '9292' }
  quickstack::load_balancer::proxy { 'swift-proxy': port => '8080' }
  quickstack::load_balancer::proxy { 'glance-registry': port => '9191' }
  quickstack::load_balancer::proxy { 'keystone-admin': port => '35357' }
  quickstack::load_balancer::proxy { 'keystone-public': port => '5000' }
  quickstack::load_balancer::proxy { 'neutron': port => '9696' }
  quickstack::load_balancer::proxy { 'nova-ec2': port => '8773' }
  quickstack::load_balancer::proxy { 'nova-compute': port => '8774' }
  quickstack::load_balancer::proxy { 'nova-metadata': port => '8775' }

  sysctl::value { 'net.ipv4.ip_nonlocal_bind': value => '1' }
}

define quickstack::load_balancer::proxy ($port) {
  include quickstack::load_balancer

  $addr = [ $quickstack::load_balancer::lb_private_vip,
            $quickstack::load_balancer::lb_public_vip ]

  haproxy::listen { $name:
    ipaddress  => $addr,
    ports      => $port,
    mode       => 'http',
    options    => {
      'option' => [ 'httplog' ],
    },
    collect_exported => false,
  }

  haproxy::balancermember { $name:
    listening_service => $name,
    ports             => $port,
    server_names      => split($quickstack::load_balancer::lb_member_names, ','),
    ipaddresses       => split($quickstack::load_balancer::lb_member_addrs, ','),
    options           => 'check',
  }
}
