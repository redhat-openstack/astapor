class quickstack::load_balancer::horizon (
 $frontend_pub_host,
 $frontend_priv_host,
 $frontend_admin_host,
 $backend_server_names,
 $backend_server_addrs,
 $backend_port = '80',
 $mode = 'http',
 $option = 'httplog'
) {

 include quickstack::load_balancer::common

  if str2bool("$::haproxy_cert_exist") {
    quickstack::load_balancer::proxy { 'horizon':
    addr                 => [ $frontend_pub_host,
                              $frontend_priv_host,
                              $frontend_admin_host ],

    port           => "443 ssl crt /etc/ssl/horizon.pem",
    mode           => $mode,
    listen_options => {
      'option'     => [ $option ],
      'cookie'     => 'SERVERID insert indirect nocache',
    },
    member_options       => [ 'check inter 1s' ],
    define_cookies       => true,
    backend_port         => $backend_port,
    backend_server_addrs => $backend_server_addrs,
    backend_server_names => $backend_server_names,
    }

    quickstack::load_balancer::proxy { 'horizon_http':
    addr                 => [ $frontend_pub_host,
                              $frontend_priv_host,
                              $frontend_admin_host ],
    port           => "80",
    mode           => $mode,
    listen_options => {
      'option'     => [ $option ],
      'reqadd'     => 'X-Forwarded-Proto:\ http',
      'redirect'   => 'scheme https if !{ ssl_fc }',
    },
    member_options       => [ 'check inter 1s' ],
    define_cookies       => true,
    backend_port         => $backend_port,
    backend_server_addrs => undef,
    backend_server_names => undef,
    }
  }

  else {
   quickstack::load_balancer::proxy { 'horizon':
   addr                 => [ $frontend_pub_host,
                             $frontend_priv_host,
                             $frontend_admin_host ],
   port           => "80",
   mode           => "$mode",
   listen_options => {
     'option'     => [ "$option" ],
     'cookie'     => 'SERVERID insert indirect nocache',
   },
   member_options       => [ 'check inter 1s' ],
   define_cookies       => true,
   backend_server_addrs => $backend_server_addrs,
   backend_server_names => $backend_server_names,
   }
  }
}
