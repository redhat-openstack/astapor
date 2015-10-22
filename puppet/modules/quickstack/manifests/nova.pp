# == Class: quickstack::nova
#
# A class to configure all nova control services
#
# === Parameters
# [*admin_password*]
#   Sets the password for the nova api config.
#
# [*amqp_hostname*]
#   (optional) Location of amqp server
#   Defaults to 'localhost'
#
# [*amqp_port*]
#   (optional) Port for amqp server
#   Defaults to '5672'
#
# [*amqp_username*]
#   (optional) amqp username
#   Defaults to '' for amqp no auth.
#
# [*amqp_password*]
#   (optional) amqp password
#   Defaults to ''.
#
# [*auth_host*]
#   Where to authenticate against for nova api, usually your Keystone
#   internal ip.
#   Defaults to 'localhost'.
#
# [*auto_assign_floating_ip*]
#   Defaults to 'true'.
#
# [*bind_address*]
#   (optional) Address to bind api service to.
#   Defaults to  '0.0.0.0'.
#
# [*cpu_allocation_ratio*]
#   (optional) CPU allocation ratio.
#   Defaults to '16'.
#
# [*db_host*]
#   (optional) Nova's database host.
#   Defaults to 'localhost'.
#
# [*db_name*]
#   (optional) Nova's database name
#   Defaults to 'nova'.
#
# [*db_password*]
#
# [*db_user*]
#   (optional) Nova's database user.
#   Defaults to 'nova'.
#
# [*default_floating_pool*]
#
# [*enabled*]
#   (optional) Whether to enable the service unit. Setting 'false' is required
#   when using pacemaker to manage services.
#   Defaults to 'true'.
# [*force_dhcp_release*]
#   Defaults to 'false'.
#
# [*glance_host*]
#   (optional) List of addresses for api server hosts.
#   Defaults to 'localhost'.
#
# [*glance_port*]
#   (optional) Port glance api is listening on for server host.
#   Defaults to '9292'.
#
# [*image_service*]
#   (optional) Service used to search for and retrieve images.
#   Defaults to 'nova.image.glance.GlanceImageService'.
#
# [*manage_service*]
#   (optional) Whether to start/stop the service. Setting 'false' is required
#   when using pacemaker to manage services.
#   Defaults to true
#
# [*max_retries*]
#   (optional) Value for max_retries in /etc/nova/nova.conf
#   Defaults to ''.
#
# [*memcached_servers*]
#   (optional) Use memcached instead of in-process cache. Supply a list of
#   memcached server IP's:Memcached Port.
#   Defaults to false
#
# [*multi_host*]
#   Defaults to 'true'.
#
# [*neutron*]
#   Whether to configure nova api to use neutron for networking.
#   Defaults to 'false'.
#
# [*neutron_metadata_proxy_secret*]
# [*qpid_heartbeat*]
#   (optional) Seconds between connection keepalive heartbeats
#   Defaults to '60'.
#
# [*ram_allocation_ratio*]
#   (optional) RAM allocation ratio.
#   Defaults to '1.5'.
#
# [*rpc_backend*]
#   (optional) The rpc backend implementation to use.
#   Defaults to 'nova.openstack.common.rpc.impl_kombu'.
#
# [*scheduler_host_subset_size*]
#   (optional) defines the subset size that a host is chosen from
#   Defaults to '1'
#
# [*verbose*]
#   (optional) Set log output to verbose output.
#   Defaults to 'false'.

class quickstack::nova (
  $admin_password,
  $amqp_heartbeat_timeout_threshold,
  $amqp_hostname                = 'localhost',
  $amqp_port                    = '5672',
  $amqp_username                = '',
  $amqp_password                = '',
  $rabbit_hosts                 = undef,
  $auth_host                    = 'localhost',
  $auto_assign_floating_ip      = 'true',
  $bind_address                 = '0.0.0.0',
  $db_host                      = 'localhost',
  $db_name                      = 'nova',
  $db_password,
  $db_user                      = 'nova',
  $default_floating_pool,
  $enabled                      = 'true',
  $force_dhcp_release           = 'false',
  $glance_host                  = 'localhost',
  $glance_port                  = '9292',
  $image_service                = 'nova.image.glance.GlanceImageService',
  $manage_service               = 'true',
  $max_retries                  = '',
  $memcached_servers            = 'false',
  $multi_host                   = 'true',
  $neutron                      = 'false',
  $neutron_metadata_proxy_secret,
  $qpid_heartbeat               = '60',
  $rpc_backend                  = 'nova.openstack.common.rpc.impl_kombu',
  $scheduler_host_subset_size   = '1',
  $ram_allocation_ratio         = '1.5',
  $cpu_allocation_ratio         = '16',
  $verbose                      = 'false',
) {

    # TODO: add ssl config here
    # bring over the ssl/not chunk from
    # controller_common, that maybe should go in a function
    $nova_sql_connection = "mysql://${db_user}:${db_password}@${db_host}/${db_name}"
    $glance_api_uri =  "http://${glance_host}:${glance_port}/v1"

    class { '::nova':
      database_connection                => $nova_sql_connection,
      image_service                      => $image_service,
      glance_api_servers                 => $glance_api_uri,
      memcached_servers                  => $memcached_servers,
      rpc_backend                        => $rpc_backend,
      verbose                            => $verbose,
      qpid_port                          => $amqp_port,
      qpid_hostname                      => $amqp_hostname,
      qpid_heartbeat                     => $qpid_heartbeat,
      qpid_username                      => $amqp_username,
      qpid_password                      => $amqp_password,
      rabbit_heartbeat_timeout_threshold => $amqp_heartbeat_timeout_threshold,
      rabbit_port                        => $amqp_port,
      rabbit_host                        => $amqp_hostname,
      rabbit_userid                      => $amqp_username,
      rabbit_password                    => $amqp_password,
      rabbit_hosts                       => $rabbit_hosts,
    }

    nova_config { 'DEFAULT/default_floating_pool':
      value => $default_floating_pool;
    }

    if $rabbit_hosts {
      nova_config { 'DEFAULT/rabbit_host': ensure => absent }
      nova_config { 'DEFAULT/rabbit_port': ensure => absent }
    }

    if $max_retries {
      nova_config {
        'DEFAULT/max_retries':      value => $max_retries;
      }
    }

    if str2bool_i("$neutron") {
      class { '::nova::api':
        admin_password                       => $admin_password,
        api_bind_address                     => $bind_address,
        auth_host                            => $auth_host,
        metadata_listen                      => $bind_address,
        enabled                              => str2bool_i("$enabled"),
        manage_service                       => str2bool_i("$manage_service"),
        neutron_metadata_proxy_shared_secret => $neutron_metadata_proxy_secret,
      }
    } else {

      nova_config {
        'DEFAULT/auto_assign_floating_ip': value => $auto_assign_floating_ip;
        'DEFAULT/multi_host':              value => $multi_host;
        'DEFAULT/force_dhcp_release':      value => $force_dhcp_release;
      }

      class { '::nova::api':
        enabled          => str2bool_i("$enabled"),
        admin_password   => $admin_password,
        api_bind_address => $bind_address,
        auth_host        => $auth_host,
        metadata_listen  => $bind_address,
        manage_service   => str2bool_i("$manage_service"),
      }
    }
    class {'::nova::scheduler':
      enabled        => str2bool_i("$enabled"),
      manage_service => str2bool_i("$manage_service"),
    }
    class {'::nova::scheduler::filter':
      scheduler_host_subset_size => $scheduler_host_subset_size,
      ram_allocation_ratio       =>  $ram_allocation_ratio,
      cpu_allocation_ratio       =>  $cpu_allocation_ratio,
    }
    class {'::nova::cert':
      enabled => str2bool_i("$enabled"),
      manage_service => str2bool_i("$manage_service"),
    }
    class {'::nova::consoleauth':
      enabled => str2bool_i("$enabled"),
      manage_service => str2bool_i("$manage_service"),
    }
    class {'::nova::conductor':
      enabled => str2bool_i("$enabled"),
      manage_service => str2bool_i("$manage_service"),
    }

    class { '::nova::vncproxy':
      host    => $bind_address,
      enabled => str2bool_i("$enabled"),
      manage_service => str2bool_i("$manage_service"),
    }
    class {'::quickstack::firewall::nova':}
}
