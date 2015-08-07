class quickstack::load_balancer::neutron (
  $frontend_pub_host,
  $frontend_priv_host,
  $frontend_admin_host,
  $backend_server_names,
  $backend_server_addrs,
  $api_port         = '9696',
  $api_mode         = 'tcp',
  $api_log          = 'tcplog',
  $timeout          = ['client 30s', 'server 30s',
                      'http-request 30s'],
) {

  include quickstack::load_balancer::common

  quickstack::load_balancer::proxy { 'neutron-api':
    addr                 => [ $frontend_pub_host,
                              $frontend_priv_host,
                              $frontend_admin_host ],
    port                 => "$api_port",
    mode                 => "$api_mode",
    listen_options       => { 'option'   => [ "$api_log" ],
                              'timeout' => $timeout,
                            },
    member_options       => [ 'check inter 1s' ],
    backend_server_addrs => $backend_server_addrs,
    backend_server_names => $backend_server_names,
  }
}
