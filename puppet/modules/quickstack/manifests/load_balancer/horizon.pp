class quickstack::load_balancer::horizon (
  $frontend_pub_host,
  $frontend_priv_host,
  $frontend_admin_host,
  $backend_server_names,
  $backend_server_addrs,
  $port = '80',
  $mode = 'http',
  $log = 'tcplog',
) {

  include quickstack::load_balancer::common

  quickstack::load_balancer::proxy { 'horizon':
    addr                 => [ $frontend_pub_host,
                              $frontend_priv_host,
                              $frontend_admin_host ],
    port           => "$port",
    mode           => "$mode",
    listen_options => {
      'option'     => [ "$log" ],
      'cookie'     => 'SERVERID insert indirect nocache',
      'timeout'    => [ 'client 180s' ],
    },
    member_options       => [ 'check inter 1s' ],
    define_cookies       => true,
    backend_server_addrs => $backend_server_addrs,
    backend_server_names => $backend_server_names,
  }
}
