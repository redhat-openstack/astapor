class quickstack::load_balancer::galera (
  $frontend_pub_host,
  $backend_server_names,
  $backend_server_addrs,
  $public_port = '3306',
  $public_mode = 'tcp',
  $timeout = '90m',
  $log = 'tcplog',
) {

  include quickstack::load_balancer::common

  quickstack::load_balancer::proxy { 'galera':
    addr                 => [ $frontend_pub_host ],
    port                 => "$public_port",
    mode                 => "$public_mode",
    listen_options       => { 'option' => [ "$log", 'httpchk', 'tcpka' ],
                              'timeout' => ["client $timeout",
                                            "server $timeout", ],
                              'stick-table' => 'type ip size 1000',
                              'stick' => 'on dst', },
    member_options       => [ 'check inter 1s',
                              'port 9200',
                              'backup',
                              'on-marked-down shutdown-sessions' ],
    backend_server_addrs => $backend_server_addrs,
    backend_server_names => $backend_server_names,
  }
}
