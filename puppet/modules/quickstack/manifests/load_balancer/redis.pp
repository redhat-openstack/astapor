# Adapted from:
# http://blog.haproxy.com/2014/01/02/haproxy-advanced-redis-health-check/

class quickstack::load_balancer::redis (
  $frontend_pub_host,
  $frontend_priv_host,
  $frontend_admin_host,
  $backend_server_names,
  $backend_server_addrs,
  $api_port = '6379',
  $api_mode = 'tcp',
  $log = 'tcplog',
) {

  include quickstack::load_balancer::common

  quickstack::load_balancer::proxy { 'redis':
    addr                 => [ $frontend_pub_host,
                              $frontend_priv_host,
                              $frontend_admin_host ],
    port                 => "$api_port",
    mode                 => "$api_mode",
    listen_options       => { 'option'   => [ "$log",
                                              "tcp-check" ],
                              'tcp-check' => ["connect",
                                              "send PING\\r\\n",
                                              "expect string +PONG",
                                              "send info\\ replication\\r\\n",
                                              "expect string role:master",
                                              "send QUIT\\r\\n",
                                              "expect string +OK"],
                              
                            },
    member_options       => [ 'check inter 1s' ],
    backend_server_addrs => $backend_server_addrs,
    backend_server_names => $backend_server_names,
  }
}
