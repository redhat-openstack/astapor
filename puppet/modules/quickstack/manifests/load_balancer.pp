class quickstack::load_balancer (
  $controller_admin_host,
  $controller_priv_host,
  $controller_pub_host,
  $backend_server_names,
  $backend_server_addrs,
  $neutron,
  $heat_cfn,
  $heat_cloudwatch,
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
    addr => [ $controller_pub_host,
              $controller_priv_host,
              $controller_admin_host ],
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
    addr => [ $controller_pub_host,
              $controller_priv_host,
              $controller_admin_host ],
    port => '5000',
    mode => 'http',
    listen_options => { 'option' => [ 'httplog' ] },
    member_options => [ 'check' ],
  }
  quickstack::load_balancer::proxy { 'keystone-admin':
    addr => [ $controller_pub_host,
              $controller_priv_host,
              $controller_admin_host ],
    port => '35357',
    mode => 'http',
    listen_options => { 'option' => [ 'httplog' ] },
    member_options => [ 'check' ],
  }
  if str2bool_i("$heat_cfn") {
    quickstack::load_balancer::proxy { 'heat-cfn':
    addr => [ $controller_pub_host,
              $controller_priv_host,
              $controller_admin_host ],
      port => '8000',
      mode => 'http',
      listen_options => { 'option' => [ 'httplog' ] },
      member_options => [ 'check' ],
    }
  }
  if str2bool_i("$heat_cloudwatch") {
    quickstack::load_balancer::proxy { 'heat-cloudwatch':
    addr => [ $controller_pub_host,
              $controller_priv_host,
              $controller_admin_host ],
      port => '8003',
      mode => 'http',
      listen_options => { 'option' => [ 'httplog' ] },
      member_options => [ 'check' ],
    }
  }
  quickstack::load_balancer::proxy { 'heat-api':
    addr => [ $controller_pub_host,
              $controller_priv_host,
              $controller_admin_host ],
    port => '8004',
    mode => 'http',
    listen_options => { 'option' => [ 'httplog' ] },
    member_options => [ 'check' ],
  }
  quickstack::load_balancer::proxy { 'swift-proxy':
    addr => [ $controller_pub_host,
              $controller_priv_host,
              $controller_admin_host ],
    port => '8080',
    mode => 'http',
    listen_options => { 'option' => [ 'httplog' ] },
    member_options => [ 'check' ],
  }
  quickstack::load_balancer::proxy { 'nova-ec2':
    addr => [ $controller_pub_host,
              $controller_priv_host,
              $controller_admin_host ],
    port => '8773',
    mode => 'http',
    listen_options => { 'option' => [ 'httplog' ] },
    member_options => [ 'check' ],
  }
  quickstack::load_balancer::proxy { 'nova-compute':
    addr => [ $controller_pub_host,
              $controller_priv_host,
              $controller_admin_host ],
    port => '8774',
    mode => 'http',
    listen_options => { 'option' => [ 'httplog' ] },
    member_options => [ 'check' ],
  }
  quickstack::load_balancer::proxy { 'nova-metadata':
    addr => [ $controller_pub_host,
              $controller_priv_host,
              $controller_admin_host ],
    port => '8775',
    mode => 'http',
    listen_options => { 'option' => [ 'httplog' ] },
    member_options => [ 'check' ],
  }
  quickstack::load_balancer::proxy { 'cinder-api':
    addr => [ $controller_pub_host,
              $controller_priv_host,
              $controller_admin_host ],
    port => '8776',
    mode => 'http',
    listen_options => { 'option' => [ 'httplog' ] },
    member_options => [ 'check' ],
  }
  quickstack::load_balancer::proxy { 'ceilometer-api':
    addr => [ $controller_pub_host,
              $controller_priv_host,
              $controller_admin_host ],
    port => '8777',
    mode => 'http',
    listen_options => { 'option' => [ 'httplog' ] },
    member_options => [ 'check' ],
  }
  quickstack::load_balancer::proxy { 'glance-registry':
    addr => [ $controller_pub_host,
              $controller_priv_host,
              $controller_admin_host ],
    port => '9191',
    mode => 'http',
    listen_options => { 'option' => [ 'httplog' ] },
    member_options => [ 'check' ],
  }
  quickstack::load_balancer::proxy { 'glance-api':
    addr => [ $controller_pub_host,
              $controller_priv_host,
              $controller_admin_host ],
    port => '9292',
    mode => 'http',
    listen_options => { 'option' => [ 'httplog' ] },
    member_options => [ 'check' ],
  }
  if str2bool_i("$neutron") {
    quickstack::load_balancer::proxy { 'neutron-api':
    addr => [ $controller_pub_host,
              $controller_priv_host,
              $controller_admin_host ],
      port => '9696',
      mode => 'http',
      listen_options => { 'option' => [ 'httplog' ] },
      member_options => [ 'check' ],
    }
  }

  sysctl::value { 'net.ipv4.ip_nonlocal_bind': value => '1' }
}
