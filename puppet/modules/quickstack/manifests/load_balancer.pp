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
    ports     => '81',
    mode      => 'http',
    options   => {
      'stats' => 'enable',
    },
    collect_exported => false,
  }

  quickstack::load_balancer::proxy { 'horizon':
    addr => [ $lb_public_vip, $lb_private_vip ],
    port => '80',
    mode => 'http',
    listen_options => {
      'option' => [ 'httplog' ],
      'cookie' => 'SERVERID insert indirect nocache',
    },
    member_options => [ 'check' ],
    define_cookies => true,
  }
  quickstack::load_balancer::proxy { 'keystone-public':
    addr => [ $lb_public_vip, $lb_private_vip ],
    port => '5000',
    listen_options => { 'option' => [ 'httplog' ] },
    member_options => [ 'check' ],
  }
  quickstack::load_balancer::proxy { 'keystone-admin':
    addr => [ $lb_public_vip, $lb_private_vip ],
    port => '35357',
    listen_options => { 'option' => [ 'httplog' ] },
    member_options => [ 'check' ],
  }  
  quickstack::load_balancer::proxy { 'heat-cfn':
    addr => [ $lb_public_vip, $lb_private_vip ],
    port => '8000',
    listen_options => { 'option' => [ 'httplog' ] },
    member_options => [ 'check' ],
  }
  quickstack::load_balancer::proxy { 'heat-api':
    addr => [ $lb_public_vip, $lb_private_vip ],
    port => '8004',
    listen_options => { 'option' => [ 'httplog' ] },
    member_options => [ 'check' ],
  }
  # quickstack::load_balancer::proxy { 'swift-proxy':
  #   addr => [ $lb_public_vip, $lb_private_vip ],
  #   port => '8080',
  #   listen_options => { 'option' => [ 'httplog' ] },
  #   member_options => [ 'check' ],
  # }
  quickstack::load_balancer::proxy { 'nova-ec2':
    addr => [ $lb_public_vip, $lb_private_vip ],
    port => '8773',
    listen_options => { 'option' => [ 'httplog' ] },
    member_options => [ 'check' ],
  }
  quickstack::load_balancer::proxy { 'nova-compute':
    addr => [ $lb_public_vip, $lb_private_vip ],
    port => '8774',
    listen_options => { 'option' => [ 'httplog' ] },
    member_options => [ 'check' ],
  }
  quickstack::load_balancer::proxy { 'nova-metadata':
    addr => [ $lb_public_vip, $lb_private_vip ],
    port => '8775',
    listen_options => { 'option' => [ 'httplog' ] },
    member_options => [ 'check' ],
  }  
  quickstack::load_balancer::proxy { 'cinder-api':
    addr => [ $lb_public_vip, $lb_private_vip ],
    port => '8776',
    listen_options => { 'option' => [ 'httplog' ] },
    member_options => [ 'check' ],
  }
  quickstack::load_balancer::proxy { 'ceilometer-api':
    addr => [ $lb_public_vip, $lb_private_vip ],
    port => '8777',
    listen_options => { 'option' => [ 'httplog' ] },
    member_options => [ 'check' ],
  }
  quickstack::load_balancer::proxy { 'glance-registry':
    addr => [ $lb_public_vip, $lb_private_vip ],
    port => '9191',
    listen_options => { 'option' => [ 'httplog' ] },
    member_options => [ 'check' ],
  }
  quickstack::load_balancer::proxy { 'glance-api':
    addr => [ $lb_public_vip, $lb_private_vip ],
    port => '9292',
    listen_options => { 'option' => [ 'httplog' ] },
    member_options => [ 'check' ],
  }
  quickstack::load_balancer::proxy { 'neutron-api':
    addr => [ $lb_public_vip, $lb_private_vip ],
    port => '9696',
    listen_options => { 'option' => [ 'httplog' ] },
    member_options => [ 'check' ],
  }

  sysctl::value { 'net.ipv4.ip_nonlocal_bind': value => '1' }
}

define quickstack::load_balancer::proxy (
  $addr,
  $port,
  $mode = 'tcp',
  $listen_options,
  $member_options,
  $define_cookies = false,
) {
  include quickstack::load_balancer

  haproxy::listen { $name:
    ipaddress => $addr,
    ports     => $port,
    mode      => $mode,
    options   => $listen_options,
    collect_exported => false,
  }

  haproxy::balancermember { $name:
    listening_service => $name,
    ports             => $port,
    server_names      => split($quickstack::load_balancer::lb_member_names, ','),
    ipaddresses       => split($quickstack::load_balancer::lb_member_addrs, ','),
    options           => $member_options,
    define_cookies    => $define_cookies,
  }
}
