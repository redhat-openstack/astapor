class quickstack::pacemaker::constraints() {

  include quickstack::pacemaker::common

  anchor {'pacemaker ordering constraints begin': }
  -> Quickstack::Pacemaker::Constraint::Haproxy_vips<| |>

  Anchor['pacemaker ordering constraints begin'] ->
  Quickstack::Pacemaker::Constraint::Base_services <| |> ->
  Anchor['pacemaker ordering constraints end']

  if (str2bool_i(map_params('include_ceilometer'))) {
    $ceilometer_public_vip  = map_params("ceilometer_public_vip")
    $ceilometer_private_vip = map_params("ceilometer_private_vip")
    $ceilometer_admin_vip   = map_params("ceilometer_admin_vip")
    $pcmk_ceilometer_group = map_params("ceilometer_group")
    quickstack::pacemaker::constraint::haproxy_vips { "$pcmk_ceilometer_group":
      public_vip  => $ceilometer_public_vip,
      private_vip => $ceilometer_private_vip,
      admin_vip   => $ceilometer_admin_vip,
    }
  }

  if (str2bool_i(map_params('include_cinder'))) {
    $pcmk_cinder_group    = map_params("cinder_group")
    quickstack::pacemaker::constraint::haproxy_vips { "$pcmk_cinder_group":
      public_vip  => map_params("cinder_public_vip"),
      private_vip => map_params("cinder_private_vip"),
      admin_vip   => map_params("cinder_admin_vip"),
    }
  }

  if (str2bool_i(map_params('include_mysql'))) {
    quickstack::pacemaker::constraint::haproxy_vips { "galera":
      public_vip  => map_params("db_vip"),
      private_vip => map_params("db_vip"),
      admin_vip   => map_params("db_vip"),
    }
  }

  if (str2bool_i(map_params('include_glance'))) {
    $pcmk_glance_group = map_params("glance_group")
    quickstack::pacemaker::constraint::haproxy_vips { "$pcmk_glance_group":
      public_vip  => map_params("glance_public_vip"),
      private_vip => map_params("glance_private_vip"),
      admin_vip   => map_params("glance_admin_vip"),
    }
  }

  if (str2bool_i(map_params('include_heat'))) {
    $heat_group              = map_params("heat_group")
    $heat_cfn_group          = map_params("heat_cfn_group")
    quickstack::pacemaker::constraint::haproxy_vips { "$heat_group":
      public_vip  => map_params("heat_public_vip"),
      private_vip => map_params("heat_private_vip"),
      admin_vip   => map_params("heat_admin_vip"),
    }
    if str2bool_i($heat_cfn_enabled) {
      quickstack::pacemaker::constraint::haproxy_vips {"$heat_cfn_group":
        public_vip  => map_params("heat_cfn_public_vip"),
        private_vip => map_params("heat_cfn_private_vip"),
        admin_vip   => map_params("heat_cfn_admin_vip"),
      }
    }
  }

  if (str2bool_i(map_params('include_horizon'))) {
    $pcmk_horizon_group = map_params("horizon_group")
    $horizon_public_vip  = map_params("horizon_public_vip")
    $horizon_private_vip = map_params("horizon_private_vip")
    $horizon_admin_vip   = map_params("horizon_admin_vip")
    quickstack::pacemaker::constraint::haproxy_vips { "$pcmk_horizon_group":
      public_vip  => $horizon_public_vip,
      private_vip => $horizon_private_vip,
      admin_vip   => $horizon_admin_vip,
    }
  }

  if (str2bool_i(map_params('include_keystone'))) {
    $keystone_group = map_params("keystone_group")
    quickstack::pacemaker::constraint::haproxy_vips { "$keystone_group":
      public_vip  => map_params("keystone_public_vip"),
      private_vip => map_params("keystone_private_vip"),
      admin_vip   => map_params("keystone_admin_vip"),
    }
  }

  if (str2bool_i(map_params('include_neutron'))) {
    $neutron_group = map_params("neutron_group")
    quickstack::pacemaker::constraint::haproxy_vips { "$neutron_group":
      public_vip  => map_params("neutron_public_vip"),
      private_vip => map_params("neutron_private_vip"),
      admin_vip   => map_params("neutron_admin_vip"),
    }
  }

  if (str2bool_i(map_params('include_nova'))) {
    $pcmk_nova_group = map_params("nova_group")
    quickstack::pacemaker::constraint::haproxy_vips { "$pcmk_nova_group":
      public_vip  => map_params("nova_public_vip"),
      private_vip => map_params("nova_private_vip"),
      admin_vip   => map_params("nova_admin_vip"),
    }
  }

  if (str2bool_i(map_params('include_amqp')) and
      map_params('amqp_provider') == 'qpid') {
    $amqp_group = map_params("amqp_group")
    quickstack::pacemaker::constraint::haproxy_vips { "$amqp_group":
      public_vip  => map_params("amqp_vip"),
      private_vip => map_params("amqp_vip"),
      admin_vip   => map_params("amqp_vip"),
    }
  }

  if (str2bool_i(map_params('include_amqp')) and
      map_params('amqp_provider') == 'rabbitmq') {
    $amqp_group = map_params("amqp_group")
    $amqp_vip = map_params("amqp_vip")
    quickstack::pacemaker::constraint::haproxy_vips { "$amqp_group":
      public_vip  => $amqp_vip,
      private_vip => $amqp_vip,
      admin_vip   => $amqp_vip,
    }
  }

  if (str2bool_i(map_params('include_swift'))) {
    include quickstack::pacemaker::swift
    $swift_internal_vip = $::quickstack::pacemaker::swift::swift_internal_vip
    $swift_group = map_params("swift_group")
    quickstack::pacemaker::constraint::haproxy_vips { "$swift_group":
      public_vip  => map_params("swift_public_vip"),
      private_vip => $swift_internal_vip,
      admin_vip   => $swift_internal_vip,
    }
  }


  if (str2bool_i(map_params('include_keystone'))) {
    quickstack::pacemaker::constraint::base_services{"base-then-keystone-constr" :
      target_resource => "keystone-clone",
    }
  }

  if (str2bool_i(map_params('include_glance'))) {
    if (str2bool_i(map_params('include_keystone'))) {
      quickstack::pacemaker::constraint::typical{ 'keystone-then-glance-constr' :
        first_resource  => "keystone-clone",
        second_resource => "glance-registry-clone",
        colocation      => false,
      }
    } else {
      quickstack::pacemaker::constraint::base_services{"base-then-glance-constr" :
        target_resource => "glance-registry-clone",
      }     
    }
  }

  if (str2bool_i(map_params('include_cinder'))) {
    if (str2bool_i(map_params('include_keystone'))) {
      quickstack::pacemaker::constraint::typical{ 'keystone-then-cinder-constr' :
        first_resource  => "keystone-clone",
        second_resource => "cinder-api-clone",
        colocation      => false,
      }
    } else {
      quickstack::pacemaker::constraint::base_services{"base-then-cinder-constr" :
        target_resource => "cinder-api-clone",
      }     
    }
  }

  if (str2bool_i(map_params('include_swift'))) {
    if (str2bool_i(map_params('include_keystone'))) {
      quickstack::pacemaker::constraint::typical{ 'keystone-then-swift-constr' :
        first_resource  => "keystone-clone",
        second_resource => "swift-proxy-clone",
        colocation      => false,
      }
    } else {
      quickstack::pacemaker::constraint::base_services{"base-then-swift-constr" :
        target_resource => "swift-proxy-clone",
      }     
    }
  }

  if (str2bool_i(map_params('include_nova'))) {
    if (str2bool_i(map_params('include_keystone'))) {
      quickstack::pacemaker::constraint::typical{ 'keystone-then-nova-constr' :
        first_resource  => "keystone-clone",
        second_resource => "openstack-nova-consoleauth-clone",
        colocation      => false,
      }
    } else {
      quickstack::pacemaker::constraint::base_services{"base-then-nova-constr" :
        target_resource => "openstack-nova-consoleauth-clone",
      }     
    }
  }

  if (str2bool_i(map_params('include_neutron'))) {
    if (str2bool_i(map_params('include_keystone'))) {
      quickstack::pacemaker::constraint::typical{ 'keystone-then-neutron-constr' :
        first_resource  => "keystone-clone",
        second_resource => "neutron-server-clone",
        colocation      => false,
      }
    } else {
      quickstack::pacemaker::constraint::base_services{"base-then-neutron-constr" :
        target_resource => "neutron-server-clone",
      }     
    }
  }

  if (str2bool_i(map_params('include_ceilometer'))) {
    if (str2bool_i(map_params('include_keystone'))) {
      Quickstack::Pacemaker::Resource::Service['openstack-ceilometer-central'] ->
      quickstack::pacemaker::constraint::typical{ 'keystone-then-ceilometer-constr' :
        first_resource  => "keystone-clone",
        second_resource => "openstack-ceilometer-central",
        colocation      => false,
      }
    } else {
      Quickstack::Pacemaker::Resource::Service['openstack-ceilometer-central'] ->
      quickstack::pacemaker::constraint::base_services{"base-then-ceilo-constr" :
        target_resource => "openstack-ceilometer-central",
      }     
    }
    if (str2bool_i(map_params('include_nosql'))) {
      Quickstack::Pacemaker::Resource::Generic['mongod'] ->
      Quickstack::Pacemaker::Resource::Service['openstack-ceilometer-central'] ->
      quickstack::pacemaker::constraint::typical{ 'mongod-then-ceilometer-constr' :
        first_resource  => "mongod-clone",
        second_resource => "openstack-ceilometer-central",
        colocation      => false,
      }
    }
  }

  anchor {'pacemaker ordering constraints end': }
}
