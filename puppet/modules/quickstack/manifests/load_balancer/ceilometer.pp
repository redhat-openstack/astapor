class quickstack::load_balancer::ceilometer (
  $frontend_pub_host,
  $frontend_priv_host,
  $frontend_admin_host,
  $backend_server_names,
  $backend_server_addrs,
  $api_port = '8777',
  $api_mode = 'tcp',
  $log = 'tcplog',
) {

  include quickstack::load_balancer::common

  quickstack::load_balancer::proxy { 'ceilometer-api':
    addr                 => [ $frontend_pub_host,
                              $frontend_priv_host,
                              $frontend_admin_host ],
    port                 => "$api_port",
    mode                 => "$api_mode",
    listen_options       => {
      'option'  => [ "$log" ],
      'timeout' => ['client 90s' ],
    },
    member_options       => [ 'check inter 1s' ],
    backend_server_addrs => $backend_server_addrs,
    backend_server_names => $backend_server_names,
  }
}
