class quickstack::pacemaker::keystone (
  $admin_email,
  $admin_password,
  $admin_tenant     = "admin",
  $admin_token,
  $db_name          = "keystone",
  $db_ssl           = "false",
  $db_ssl_ca        = undef,
  $db_type          = "mysql",
  $db_user          = "keystone",
  $debug            = "false",
  $enabled          = "true",
  $idle_timeout     = "200",
  $keystonerc       = "false",
  $public_protocol  = "http",
  $region           = "RegionOne",
  $token_driver     = "keystone.token.backends.sql.Token",
  $token_format     = "PKI",
  $use_syslog       = "false",
  $log_facility     = 'LOG_USER',
  $verbose          = 'false',
  $ceilometer       = "false",
  $cinder           = "true",
  $glance           = "true",
  $heat             = "true",
  $heat_cfn         = "true",
  $nova             = "true",
  $swift            = "false",
) {

  include quickstack::pacemaker::common

  if (str2bool_i(map_params('include_keystone'))) {
    $keystone_group = map_params("keystone_group")
    $keystone_private_vip = map_params("keystone_private_vip")

    # TODO: once the keystone class stops incorrectly interpreting
    # $enabled = true|false as $service_ensure = 'running'|'stopped',
    # we can revert to relying on the $::pcs_setup_keystone fact
    # as whether or not the keystone service untouched (i.e.,
    # what we want to do is assume keystone is under pacemaker
    # control if $::pcs_setup_keystone is true and leave the
    # keystone service alone)
    $_enabled = true

    # because the dep on stack::keystone is not enough for some reason...
    Exec['i-am-keystone-vip-OR-keystone-is-up-on-vip'] -> Service['keystone'] -> Exec['pcs-keystone-server-set-up']
    Exec['i-am-keystone-vip-OR-keystone-is-up-on-vip'] -> Exec<| title == 'keystone-manage db_sync'|> ->
    Exec['pcs-keystone-server-set-up']
    Exec['i-am-keystone-vip-OR-keystone-is-up-on-vip'] -> Exec['keystone-manage pki_setup'] -> Exec['pcs-keystone-server-set-up']
    Exec['i-am-keystone-vip-OR-keystone-is-up-on-vip'] -> Keystone_user<| |> -> Exec['pcs-keystone-server-set-up']
    Exec['i-am-keystone-vip-OR-keystone-is-up-on-vip'] -> Keystone_user_role<| |> -> Exec['pcs-keystone-server-set-up']
    Exec['i-am-keystone-vip-OR-keystone-is-up-on-vip'] -> Keystone_endpoint<| |> -> Exec['pcs-keystone-server-set-up']
    Exec['i-am-keystone-vip-OR-keystone-is-up-on-vip'] -> Keystone_tenant<| |> -> Exec['pcs-keystone-server-set-up']
    Exec['i-am-keystone-vip-OR-keystone-is-up-on-vip'] -> Keystone_service<| |> -> Exec['pcs-keystone-server-set-up']

    if (str2bool_i(map_params('include_mysql'))) {
      Exec['galera-online'] -> Exec['i-am-keystone-vip-OR-keystone-is-up-on-vip']
    }

    class {"::quickstack::load_balancer::keystone":
      frontend_pub_host    => map_params("keystone_public_vip"),
      frontend_priv_host   => map_params("keystone_private_vip"),
      frontend_admin_host  => map_params("keystone_admin_vip"),
      backend_server_names => map_params("lb_backend_server_names"),
      backend_server_addrs => map_params("lb_backend_server_addrs"),
    }

    keystone_config {
      'DEFAULT/max_retries':      value => '-1';
    }

    Class['::quickstack::pacemaker::common'] ->

    quickstack::pacemaker::vips { "$keystone_group":
      public_vip  => map_params("keystone_public_vip"),
      private_vip => map_params("keystone_private_vip"),
      admin_vip   => map_params("keystone_admin_vip"),
    } ->
    class {'::quickstack::firewall::keystone':} ->
    exec {"i-am-keystone-vip-OR-keystone-is-up-on-vip":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/tmp/ha-all-in-one-util.bash i_am_vip $keystone_private_vip || /tmp/ha-all-in-one-util.bash property_exists keystone",
      unless   => "/tmp/ha-all-in-one-util.bash i_am_vip $keystone_private_vip || /tmp/ha-all-in-one-util.bash property_exists keystone",
    } ->
    class {"::quickstack::keystone::common":
      admin_token                 => "$admin_token",
      bind_host                   => map_params("local_bind_addr"),
      db_host                     => map_params("db_vip"),
      db_name                     => "$db_name",
      db_password                 => map_params("keystone_db_password"),
      db_ssl                      => str2bool_i("$db_ssl"),
      db_ssl_ca                   => "$db_ssl_ca",
      db_type                     => "$db_type",
      db_user                     => "$db_user",
      debug                       => str2bool_i("$debug"),
      enabled                     => $_enabled,
      idle_timeout                => "$idle_timeout",
      log_facility                => "$log_facility",
      token_driver                => "$token_driver",
      token_format                => "$token_format",
      use_syslog                  => str2bool_i("$use_syslog"),
      verbose                     => str2bool_i("$verbose"),
    } ->
    class {"::quickstack::keystone::endpoints":
      admin_address               => map_params("keystone_admin_vip"),
      admin_email                 => "$admin_email",
      admin_password              => "$admin_password",
      admin_tenant                => "$admin_tenant",
      enabled                     => $_enabled,
      internal_address            => map_params("keystone_private_vip"),
      public_address              => map_params("keystone_public_vip"),
      public_protocol             => "$public_protocol",
      region                      => "$region",
      ceilometer                  => str2bool_i("$ceilometer"),
      ceilometer_user_password    => map_params("ceilometer_user_password"),
      ceilometer_public_address   => map_params("ceilometer_public_vip"),
      ceilometer_internal_address => map_params("ceilometer_private_vip"),
      ceilometer_admin_address    => map_params("ceilometer_admin_vip"),
      cinder                      => str2bool_i("$cinder"),
      cinder_user_password        => map_params("cinder_user_password"),
      cinder_public_address       => map_params("cinder_public_vip"),
      cinder_internal_address     => map_params("cinder_private_vip"),
      cinder_admin_address        => map_params("cinder_admin_vip"),
      glance                      => str2bool_i("$glance"),
      glance_user_password        => map_params("glance_user_password"),
      glance_public_address       => map_params("glance_public_vip"),
      glance_internal_address     => map_params("glance_private_vip"),
      glance_admin_address        => map_params("glance_admin_vip"),
      heat                        => str2bool_i("$heat"),
      heat_user_password          => map_params("heat_user_password"),
      heat_public_address         => map_params("heat_public_vip"),
      heat_internal_address       => map_params("heat_private_vip"),
      heat_admin_address          => map_params("heat_admin_vip"),
      heat_cfn                    => str2bool_i("$heat_cfn"),
      heat_cfn_user_password      => map_params("heat_cfn_user_password"),
      heat_cfn_public_address     => map_params("heat_cfn_public_vip"),
      heat_cfn_internal_address   => map_params("heat_cfn_private_vip"),
      heat_cfn_admin_address      => map_params("heat_cfn_admin_vip"),
      neutron                     => str2bool_i(map_params("neutron")),
      neutron_user_password       => map_params("neutron_user_password"),
      neutron_public_address      => map_params("neutron_public_vip"),
      neutron_internal_address    => map_params("neutron_private_vip"),
      neutron_admin_address       => map_params("neutron_admin_vip"),
      nova                        => str2bool_i("$nova"),
      nova_user_password          => map_params("nova_user_password"),
      nova_public_address         => map_params("nova_public_vip"),
      nova_internal_address       => map_params("nova_private_vip"),
      nova_admin_address          => map_params("nova_admin_vip"),
      swift                       => str2bool_i("$swift"),
      swift_user_password         => map_params("swift_user_password"),
      swift_public_address        => map_params("swift_public_vip"),
      swift_internal_address      => map_params("swift_public_vip"),
      swift_admin_address         => map_params("swift_public_vip"),
    } ->
    class { "::quickstack::pacemaker::rsync::keystone":
      keystone_private_vip => map_params("keystone_private_vip"),
    } ->
    exec {"pcs-keystone-server-set-up":
      command => "/usr/sbin/pcs property set keystone=running --force",
    } ->
    exec {"pcs-keystone-server-set-up-on-this-node":
      command => "/tmp/ha-all-in-one-util.bash update_my_node_property keystone"
    } ->
    exec {"all-keystone-nodes-are-up":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/tmp/ha-all-in-one-util.bash all_members_include keystone",
    } ->
    quickstack::pacemaker::resource::service {'openstack-keystone':
      clone   => true,
      options => 'start-delay=10s',
    }
    ->
    Anchor['pacemaker ordering constraints begin']
    # TODO: Consider if we should pre-emptively purge any directories keystone has
    # created in /tmp

    if "$keystonerc" == "true" {
      class { '::quickstack::admin_client':
        admin_password        => "$admin_password",
        controller_admin_host => map_params("keystone_admin_vip"),
      }
    }
  }
}
