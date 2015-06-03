class quickstack::pacemaker::load_balancer {

  include quickstack::pacemaker::common
  include quickstack::load_balancer::common

  $loadbalancer_group = map_params("loadbalancer_group")
  $loadbalancer_vip   = map_params("loadbalancer_vip")

  quickstack::pacemaker::vips { "$loadbalancer_group":
    public_vip  => $loadbalancer_vip,
    private_vip => $loadbalancer_vip,
    admin_vip   => $loadbalancer_vip,
  } ->

  Service['haproxy'] ->
  exec {"pcs-haproxy-server-set-up-on-this-node":
    command => "/tmp/ha-all-in-one-util.bash update_my_node_property haproxy"
  } ->
  exec {"all-haproxy-nodes-are-up":
    timeout   => 3600,
    tries     => 360,
    try_sleep => 10,
    command   => "/tmp/ha-all-in-one-util.bash all_members_include haproxy",

  } ->
  quickstack::pacemaker::resource::generic {'haproxy':
    clone_opts      => '',
    operation_opts => 'monitor start-delay=10s',
  } ->
  Anchor['pacemaker ordering constraints begin']
}
