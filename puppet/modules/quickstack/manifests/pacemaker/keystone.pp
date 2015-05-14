class quickstack::pacemaker::keystone (
  $admin_email,
  $admin_password,
  $admin_tenant                             = "admin",
  $admin_token,
  $db_name                                  = "keystone",
  $db_ssl                                   = "false",
  $db_ssl_ca                                = undef,
  $db_type                                  = "mysql",
  $db_user                                  = "keystone",
  $debug                                    = "false",
  $enabled                                  = "true",
  $idle_timeout                             = "200",
  $keystonerc                               = "false",
  $public_protocol                          = "http",
  $region                                   = "RegionOne",
  $token_driver                             = "keystone.token.backends.sql.Token",
  $token_format                             = "PKI",
  $use_syslog                               = "false",
  $log_facility                             = 'LOG_USER',
  $verbose                                  = 'false',
  $ceilometer                               = 'true',
  $cinder                                   = "true",
  $glance                                   = "true",
  $heat                                     = "true",
  $heat_cfn                                 = "true",
  $nova                                     = "true",
  $swift                                    = "false",
  $keystone_identity_backend                = 'sql',
  $ldap_url                                 = '',
  $ldap_user                                = '',
  $ldap_password                            = '',
  $ldap_suffix                              = '',
  $ldap_query_scope                         = '',
  $ldap_page_size                           = '',
  $ldap_user_tree_dn                        = '',
  $ldap_user_filter                         = '',
  $ldap_user_objectclass                    = '',
  $ldap_user_id_attribute                   = '',
  $ldap_user_name_attribute                 = '',
  $ldap_user_mail_attribute                 = '',
  $ldap_user_enabled_attribute              = '',
  $ldap_user_enabled_mask                   = '',
  $ldap_user_enabled_default                = '',
  $ldap_user_enabled_invert                 = '',
  $ldap_user_attribute_ignore               = '',
  $ldap_user_default_project_id_attribute   = '',
  $ldap_user_allow_create                   = '',
  $ldap_user_allow_update                   = '',
  $ldap_user_allow_delete                   = '',
  $ldap_user_pass_attribute                 = '',
  $ldap_user_enabled_emulation              = '',
  $ldap_user_enabled_emulation_dn           = '',
  $ldap_user_additional_attribute_mapping   = '',
  $ldap_tenant_tree_dn                      = '',
  $ldap_tenant_filter                       = '',
  $ldap_tenant_objectclass                  = '',
  $ldap_tenant_id_attribute                 = '',
  $ldap_tenant_member_attribute             = '',
  $ldap_tenant_desc_attribute               = '',
  $ldap_tenant_name_attribute               = '',
  $ldap_tenant_enabled_attribute            = '',
  $ldap_tenant_domain_id_attribute          = '',
  $ldap_tenant_attribute_ignore             = '',
  $ldap_tenant_allow_create                 = '',
  $ldap_tenant_allow_update                 = '',
  $ldap_tenant_allow_delete                 = '',
  $ldap_tenant_enabled_emulation            = '',
  $ldap_tenant_enabled_emulation_dn         = '',
  $ldap_tenant_additional_attribute_mapping = '',
  $ldap_role_tree_dn                        = '',
  $ldap_role_filter                         = '',
  $ldap_role_objectclass                    = '',
  $ldap_role_id_attribute                   = '',
  $ldap_role_name_attribute                 = '',
  $ldap_role_member_attribute               = '',
  $ldap_role_attribute_ignore               = '',
  $ldap_role_allow_create                   = '',
  $ldap_role_allow_update                   = '',
  $ldap_role_allow_delete                   = '',
  $ldap_role_additional_attribute_mapping   = '',
  $ldap_group_tree_dn                       = '',
  $ldap_group_filter                        = '',
  $ldap_group_objectclass                   = '',
  $ldap_group_id_attribute                  = '',
  $ldap_group_name_attribute                = '',
  $ldap_group_member_attribute              = '',
  $ldap_group_desc_attribute                = '',
  $ldap_group_attribute_ignore              = '',
  $ldap_group_allow_create                  = '',
  $ldap_group_allow_update                  = '',
  $ldap_group_allow_delete                  = '',
  $ldap_group_additional_attribute_mapping  = '',
  $ldap_use_tls                             = '',
  $ldap_tls_cacertdir                       = '',
  $ldap_tls_cacertfile                      = '',
  $ldap_tls_req_cert                        = '',
  $ldap_identity_driver                     = 'keystone.identity.backends.ldap.Identity',
  $ldap_assignment_driver                   = 'keystone.assignment.backends.sql.Assignment',
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
      Anchor['galera-online'] -> Exec['i-am-keystone-vip-OR-keystone-is-up-on-vip']
    }
    if (str2bool_i(map_params('include_heat'))) {
      if (is_configured('heat')) {
        $_extra_admin_roles = ['heat_stack_owner']
      } else {
        $_extra_admin_roles = []
      }
    } else {
      $_extra_admin_roles = []
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
      admin_token  => "$admin_token",
      amqp_host    => map_params("amqp_vip"),
      amqp_port    => map_params("amqp_port"),
      rabbit_hosts => map_params("rabbitmq_hosts"),
      bind_host    => map_params("local_bind_addr"),
      db_host      => map_params("db_vip"),
      db_name      => "$db_name",
      db_password  => map_params("keystone_db_password"),
      db_ssl       => str2bool_i("$db_ssl"),
      db_ssl_ca    => "$db_ssl_ca",
      db_type      => "$db_type",
      db_user      => "$db_user",
      debug        => str2bool_i("$debug"),
      enabled      => $_enabled,
      idle_timeout => "$idle_timeout",
      log_facility => "$log_facility",
      token_driver => "$token_driver",
      token_format => "$token_format",
      use_syslog   => str2bool_i("$use_syslog"),
      verbose      => str2bool_i("$verbose"),
    } ->
    class {"::quickstack::keystone::endpoints":
      admin_address               => map_params("keystone_admin_vip"),
      admin_email                 => "$admin_email",
      admin_password              => "$admin_password",
      admin_tenant                => "$admin_tenant",
      enabled                     => $_enabled,
      extra_admin_roles           => $_extra_admin_roles,
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
    quickstack::pacemaker::resource::generic {'keystone':
      clone_opts    => '',
      resource_name => "openstack-keystone",
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
    # not ready yet
#        user_enabled_invert                 => $ldap_user_enabled_invert,
    if $keystone_identity_backend == 'ldap' {
      class {'::keystone::ldap':
        url                                 => empty_to_undef($ldap_url),
        user                                => empty_to_undef($ldap_user),
        password                            => empty_to_undef($ldap_password),
        suffix                              => empty_to_undef($ldap_suffix),
        query_scope                         => empty_to_undef($ldap_query_scope),
        page_size                           => empty_to_undef($ldap_page_size),
        user_tree_dn                        => empty_to_undef($ldap_user_tree_dn),
        user_filter                         => empty_to_undef($ldap_user_filter),
        user_objectclass                    => empty_to_undef($ldap_user_objectclass),
        user_id_attribute                   => empty_to_undef($ldap_user_id_attribute),
        user_name_attribute                 => empty_to_undef($ldap_user_name_attribute),
        user_mail_attribute                 => empty_to_undef($ldap_user_mail_attribute),
        user_enabled_attribute              => empty_to_undef($ldap_user_enabled_attribute),
        user_enabled_mask                   => empty_to_undef($ldap_user_enabled_mask),
        user_enabled_default                => empty_to_undef($ldap_user_enabled_default),
        user_attribute_ignore               => empty_to_undef($ldap_user_attribute_ignore),
        user_default_project_id_attribute   => empty_to_undef($ldap_user_default_project_id_attribute),
        user_allow_create                   => str2bool_i($ldap_user_allow_create),
        user_allow_update                   => str2bool_i($ldap_user_allow_update),
        user_allow_delete                   => str2bool_i($ldap_user_allow_delete),
        user_pass_attribute                 => empty_to_undef($ldap_user_pass_attribute),
        user_enabled_emulation              => str2bool_i($ldap_user_enabled_emulation),
        user_enabled_emulation_dn           => empty_to_undef($ldap_user_enabled_emulation_dn),
        user_additional_attribute_mapping   => empty_to_undef($ldap_user_additional_attribute_mapping),
        tenant_tree_dn                      => empty_to_undef($ldap_tenant_tree_dn),
        tenant_filter                       => empty_to_undef($ldap_tenant_filter),
        tenant_objectclass                  => empty_to_undef($ldap_tenant_objectclass),
        tenant_id_attribute                 => empty_to_undef($ldap_tenant_id_attribute),
        tenant_member_attribute             => empty_to_undef($ldap_tenant_member_attribute),
        tenant_desc_attribute               => empty_to_undef($ldap_tenant_desc_attribute),
        tenant_name_attribute               => empty_to_undef($ldap_tenant_name_attribute),
        tenant_enabled_attribute            => empty_to_undef($ldap_tenant_enabled_attribute),
        tenant_domain_id_attribute          => empty_to_undef($ldap_tenant_domain_id_attribute),
        tenant_attribute_ignore             => empty_to_undef($ldap_tenant_attribute_ignore),
        tenant_allow_create                 => str2bool_i($ldap_tenant_allow_create),
        tenant_allow_update                 => str2bool_i($ldap_tenant_allow_update),
        tenant_allow_delete                 => str2bool_i($ldap_tenant_allow_delete),
        tenant_enabled_emulation            => str2bool_i($ldap_tenant_enabled_emulation),
        tenant_enabled_emulation_dn         => empty_to_undef($ldap_tenant_enabled_emulation_dn),
        tenant_additional_attribute_mapping => empty_to_undef($ldap_tenant_additional_attribute_mapping),
        role_tree_dn                        => empty_to_undef($ldap_role_tree_dn),
        role_filter                         => empty_to_undef($ldap_role_filter),
        role_objectclass                    => empty_to_undef($ldap_role_objectclass),
        role_id_attribute                   => empty_to_undef($ldap_role_id_attribute),
        role_name_attribute                 => empty_to_undef($ldap_role_name_attribute),
        role_member_attribute               => empty_to_undef($ldap_role_member_attribute),
        role_attribute_ignore               => empty_to_undef($ldap_role_attribute_ignore),
        role_allow_create                   => str2bool_i($ldap_role_allow_create),
        role_allow_update                   => str2bool_i($ldap_role_allow_update),
        role_allow_delete                   => str2bool_i($ldap_role_allow_delete),
        role_additional_attribute_mapping   => empty_to_undef($ldap_role_additional_attribute_mapping),
        group_tree_dn                       => empty_to_undef($ldap_group_tree_dn),
        group_filter                        => empty_to_undef($ldap_group_filter),
        group_objectclass                   => empty_to_undef($ldap_group_objectclass),
        group_id_attribute                  => empty_to_undef($ldap_group_id_attribute),
        group_name_attribute                => empty_to_undef($ldap_group_name_attribute),
        group_member_attribute              => empty_to_undef($ldap_group_member_attribute),
        group_desc_attribute                => empty_to_undef($ldap_group_desc_attribute),
        group_attribute_ignore              => empty_to_undef($ldap_group_attribute_ignore),
        group_allow_create                  => str2bool_i($ldap_group_allow_create),
        group_allow_update                  => str2bool_i($ldap_group_allow_update),
        group_allow_delete                  => str2bool_i($ldap_group_allow_delete),
        group_additional_attribute_mapping  => empty_to_undef($ldap_group_additional_attribute_mapping),
        use_tls                             => str2bool_i($ldap_use_tls),
        tls_cacertdir                       => empty_to_undef($ldap_tls_cacertdir),
        tls_cacertfile                      => empty_to_undef($ldap_tls_cacertfile),
        tls_req_cert                        => empty_to_undef($ldap_tls_req_cert),
        identity_driver                     => empty_to_undef($ldap_identity_driver),
        assignment_driver                   => empty_to_undef($ldap_assignment_driver),
        before                              => Class["::quickstack::keystone::endpoints"]
      }
    }
  }
}
