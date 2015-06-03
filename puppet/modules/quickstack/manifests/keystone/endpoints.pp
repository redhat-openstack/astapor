#
# == Class: quickstack::keystone::endpoints
#
# Configures Keystone endpoints.
#
# === Parameters
#
# [admin_email] Email address of system admin. Required.
# [admin_password] Auth password for admin user. Required.
# [extra_admin_roles] Additional keystone roles to be given to the admin user.
# Optional.  Defaults to []
# [glance_user_password] Auth password for glance user. Required.
# [nova_user_password] Auth password for nova user. Required.
# [public_address] Public address where keystone can be accessed. Required.
# [public_protocol] Public protocol over which keystone can be accessed. Defaults to 'http'
#   Supports PKI and UUID.
# [admin_tenant] Name of keystone admin tenant. Optional. Defaults to  'admin'
#   Optional.  Defaults to 'keystone.token.backends.sql.Token'
# [internal_address] Internal address for keystone. Optional. Defaults to  $public_address
# [admin_address] Keystone admin address. Optional. Defaults to  $internal_address
# [glance] Set up glance endpoints and auth. Optional. Defaults to  true
# [nova] Set up nova endpoints and auth. Optional. Defaults to  true
# [swift] Set up swift endpoints and auth. Optional. Defaults to false
# [swift_user_password]
#   Auth password for swift.
#   (Optional) Defaults to false.
# [enabled] If the service is active (true) or passive (false).
#   Optional. Defaults to  true
#
# === Example
#
# class { 'quickstack::keystone::endpoints':
#   admin_email           => 'root@localhost',
#   admin_password        => 'changeme',
#   glance_user_password  => 'glance',
#   nova_user_password    => 'nova',
#   cinder_user_password  => 'cinder',
#   neutron_user_password => 'neutron',
#   public_address        => '192.168.1.1',
#  }

class quickstack::keystone::endpoints (
  $admin_address               = false,
  $admin_email,
  $admin_password,
  $admin_tenant                = 'admin',
  $enabled                     = true,
  $extra_admin_roles           = [],
  $internal_address            = false,
  $public_address,
  $public_protocol             = 'http',
  $region                      = 'RegionOne',
  # ceilometer
  $ceilometer                  = false,
  $ceilometer_user_password    = false,
  $ceilometer_public_address   = false,
  $ceilometer_internal_address = false,
  $ceilometer_admin_address    = false,
  # cinder
  $cinder                      = true,
  $cinder_user_password,
  $cinder_public_address       = false,
  $cinder_internal_address     = false,
  $cinder_admin_address        = false,
  # glance
  $glance                      = true,
  $glance_user_password,
  $glance_public_address       = false,
  $glance_internal_address     = false,
  $glance_admin_address        = false,
  # heat
  $heat                        = false,
  $heat_user_password          = false,
  $heat_public_address         = false,
  $heat_internal_address       = false,
  $heat_admin_address          = false,
  # heat cloudformation api
  $heat_cfn                    = false,
  $heat_cfn_user_password      = false,
  $heat_cfn_public_address     = false,
  $heat_cfn_internal_address   = false,
  $heat_cfn_admin_address      = false,
  # neutron
  $neutron                     = true,
  $neutron_user_password,
  $neutron_public_address      = false,
  $neutron_internal_address    = false,
  $neutron_admin_address       = false,
  # nova
  $nova                        = true,
  $nova_user_password,
  $nova_public_address         = false,
  $nova_internal_address       = false,
  $nova_admin_address          = false,
  # swift
  $swift                       = false,
  $swift_user_password         = false,
  $swift_public_address        = false,
  $swift_internal_address      = false,
  $swift_admin_address         = false,
) {

  validate_array($extra_admin_roles)
  # We have to do all of this crazy munging b/c parameters are not
  # set procedurally in Puppet
  if($internal_address) {
    $internal_real = $internal_address
  } else {
    $internal_real = $public_address
  }
  if($admin_address) {
    $admin_real = $admin_address
  } else {
    $admin_real = $internal_real
  }
  if($glance_public_address) {
    $glance_public_real = $glance_public_address
  } else {
    $glance_public_real = $public_address
  }
  if($glance_internal_address) {
    $glance_internal_real = $glance_internal_address
  } else {
    $glance_internal_real = $glance_public_real
  }
  if($glance_admin_address) {
    $glance_admin_real = $glance_admin_address
  } else {
    $glance_admin_real = $glance_internal_real
  }
  if($nova_public_address) {
    $nova_public_real = $nova_public_address
  } else {
    $nova_public_real = $public_address
  }
  if($nova_internal_address) {
    $nova_internal_real = $nova_internal_address
  } else {
    $nova_internal_real = $nova_public_real
  }
  if($nova_admin_address) {
    $nova_admin_real = $nova_admin_address
  } else {
    $nova_admin_real = $nova_internal_real
  }
  if($cinder_public_address) {
    $cinder_public_real = $cinder_public_address
  } else {
    $cinder_public_real = $public_address
  }
  if($cinder_internal_address) {
    $cinder_internal_real = $cinder_internal_address
  } else {
    $cinder_internal_real = $cinder_public_real
  }
  if($cinder_admin_address) {
    $cinder_admin_real = $cinder_admin_address
  } else {
    $cinder_admin_real = $cinder_internal_real
  }
  if($neutron_public_address) {
    $neutron_public_real = $neutron_public_address
  } else {
    $neutron_public_real = $public_address
  }
  if($neutron_internal_address) {
    $neutron_internal_real = $neutron_internal_address
  } else {
    $neutron_internal_real = $neutron_public_real
  }
  if($neutron_admin_address) {
    $neutron_admin_real = $neutron_admin_address
  } else {
    $neutron_admin_real = $neutron_internal_real
  }
  if($ceilometer_public_address) {
    $ceilometer_public_real = $ceilometer_public_address
  } else {
    $ceilometer_public_real = $public_address
  }
  if($ceilometer_internal_address) {
    $ceilometer_internal_real = $ceilometer_internal_address
  } else {
    $ceilometer_internal_real = $ceilometer_public_real
  }
  if($ceilometer_admin_address) {
    $ceilometer_admin_real = $ceilometer_admin_address
  } else {
    $ceilometer_admin_real = $ceilometer_internal_real
  }
  if($swift_public_address) {
    $swift_public_real = $swift_public_address
  } else {
    $swift_public_real = $public_address
  }
  if($swift_internal_address) {
    $swift_internal_real = $swift_internal_address
  } else {
    $swift_internal_real = $swift_public_real
  }
  if($swift_admin_address) {
    $swift_admin_real = $swift_admin_address
  } else {
    $swift_admin_real = $swift_internal_real
  }
  if($heat_public_address) {
    $heat_public_real = $heat_public_address
  } else {
    $heat_public_real = $public_address
  }
  if($heat_internal_address) {
    $heat_internal_real = $heat_internal_address
  } else {
    $heat_internal_real = $heat_public_real
  }
  if($heat_admin_address) {
    $heat_admin_real = $heat_admin_address
  } else {
    $heat_admin_real = $heat_internal_real
  }
  if($heat_cfn_public_address) {
    $heat_cfn_public_real = $heat_cfn_public_address
  } else {
    $heat_cfn_public_real = $public_address
  }
  if($heat_cfn_internal_address) {
    $heat_cfn_internal_real = $heat_cfn_internal_address
  } else {
    $heat_cfn_internal_real = $heat_cfn_public_real
  }
  if($heat_cfn_admin_address) {
    $heat_cfn_admin_real = $heat_cfn_admin_address
  } else {
    $heat_cfn_admin_real = $heat_cfn_internal_real
  }

  if $enabled {
    # Setup the admin user
    $_base_admin_roles = ['admin']
    if $heat {
      if (size($extra_admin_roles) > 0) {
        $_admin_roles = concat($_base_admin_roles,$extra_admin_roles)
      } else {
        $_admin_roles = $_base_admin_roles
      }
    } else {
      $_admin_roles = $_base_admin_roles
    }
    class { 'keystone::roles::admin':
      email        => $admin_email,
      password     => $admin_password,
      admin_roles  => $_admin_roles,
      admin_tenant => $admin_tenant,
    }
    contain keystone::roles::admin

    # Setup the Keystone Identity Endpoint
    keystone::resource::service_identity {'identity_endpoint':
      public_url   => "http://${public_address}:5000/v2.0",
      admin_url    => "http://${admin_real}:35357/v2.0",
      internal_url => "http://${internal_real}:5000/v2.0",
      region       => $region,
      service_type => 'identity',
    }

    # Configure Glance endpoint in Keystone
    if $glance {
      class { 'glance::keystone::auth':
        password         => $glance_user_password,
        public_address   => $glance_public_real,
        public_protocol  => $public_protocol,
        admin_address    => $glance_admin_real,
        internal_address => $glance_internal_real,
        region           => $region,
      }
      contain glance::keystone::auth
    }

    # Configure Nova endpoint in Keystone
    if $nova {
      class { 'nova::keystone::auth':
        password         => $nova_user_password,
        public_address   => $nova_public_real,
        public_protocol  => $public_protocol,
        admin_address    => $nova_admin_real,
        internal_address => $nova_internal_real,
        region           => $region,
      }
      contain nova::keystone::auth
    }

    # Configure Cinder endpoint in Keystone
    if $cinder {
      class { 'cinder::keystone::auth':
        password         => $cinder_user_password,
        public_address   => $cinder_public_real,
        public_protocol  => $public_protocol,
        admin_address    => $cinder_admin_real,
        internal_address => $cinder_internal_real,
        region           => $region,
      }
      contain cinder::keystone::auth
    }

    if $neutron {
      class { 'neutron::keystone::auth':
        password         => $neutron_user_password,
        public_address   => $neutron_public_real,
        public_protocol  => $public_protocol,
        admin_address    => $neutron_admin_real,
        internal_address => $neutron_internal_real,
        region           => $region,
      }
      contain neutron::keystone::auth
    }

    if $ceilometer {

      if ! $ceilometer_user_password {
        fail('Must set a ceilometer_user_password when ceilometer auth is being configured')
      }

      class { 'ceilometer::keystone::auth':
        password         => $ceilometer_user_password,
        public_address   => $ceilometer_public_real,
        public_protocol  => $public_protocol,
        admin_address    => $ceilometer_admin_real,
        internal_address => $ceilometer_internal_real,
        region           => $region,
      }
      contain ceilometer::keystone::auth
    }

    if $swift {

      if ! $swift_user_password {
        fail('Must set a swift_user_password when swift auth is being configured')
      }

      class { 'swift::keystone::auth':
        password         => $swift_user_password,
        public_address   => $swift_public_real,
        public_protocol  => $public_protocol,
        admin_address    => $swift_admin_real,
        internal_address => $swift_internal_real,
        region           => $region,
      }
      contain swift::keystone::auth
    }

    if $heat {

      if ! $heat_user_password {
        fail('Must set a heat_user_password when heat auth is being configured')
      }

      class { 'heat::keystone::auth':
        password         => $heat_user_password,
        public_address   => $heat_public_real,
        public_protocol  => $public_protocol,
        admin_address    => $heat_admin_real,
        internal_address => $heat_internal_real,
        region           => $region,
      }
      contain heat::keystone::auth
    }

    if $heat_cfn {

      if ! $heat_cfn_user_password {
        fail('Must set a heat_cfn_user_password when heat_cfn auth is being configured')
      }

      class { 'heat::keystone::auth_cfn':
        password         => $heat_cfn_user_password,
        public_address   => $heat_cfn_public_real,
        public_protocol  => $public_protocol,
        admin_address    => $heat_cfn_admin_real,
        internal_address => $heat_cfn_internal_real,
        region           => $region,
      }
      contain heat::keystone::auth_cfn
    }
  }
}
