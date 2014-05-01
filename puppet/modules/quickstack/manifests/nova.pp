# == Class: quickstack::nova
#
# A class to configure all nova control services
#
# === Parameters
# [*admin_password*]
#   Sets the password for the nova api config.
# [*auth_host*]
#   Where to authenticate against for nova api, usually your Keystone
#   internal ip.
#   Defaults to 'localhost'.
# [*auto_assign_floating_ip*]
#   Defaults to 'true'.
# [*bind_address*]
#   (optional) Address to bind api service to.
#   Defaults to  '0.0.0.0'.
# [*db_host*]
#   (optional) Nova's database host.
#   Defaults to 'localhost'.
# [*db_name*]
#   (optional) Nova's database name
#   Defaults to 'nova'.
# [*db_password*]
# [*db_user*]
#   (optional) Nova's database user.
#   Defaults to 'nova'.
# [*default_floating_pool*]
# [*force_dhcp_release*]
#   Defaults to 'false'.
# [*glance_host*]
#   (optional) List of addresses for api server hosts.
#   Defaults to 'localhost'.
# [*glance_port*]
#   (optional) Port glance api is listening on for server host.
#   Defaults to '9292'.
# [*image_service*]
#   (optional) Service used to search for and retrieve images.
#   Defaults to 'nova.image.glance.GlanceImageService'.
# [*memcached_servers*]
#   (optional) Use memcached instead of in-process cache. Supply a list of
#   memcached server IP's:Memcached Port.
#   Defaults to false
# [*multi_host*]
#   Defaults to 'true'.
# [*neutron*]
#   Whether to configure nova api to use neutron for networking.
#   Defaults to 'false'.
# [*neutron_metadata_proxy_secret*]
# [*qpid_heartbeat*]
#   (optional) Seconds between connection keepalive heartbeats
#   Defaults to '60'.
# [*amqp_hostname*]
#   (optional) Location of amqp server
#   Defaults to 'localhost'
# [*amqp_port*]
#   (optional) Port for amqp server
#   Defaults to '5672'
# [*amqp_username*]
#   (optional) amqp username
#   Defaults to '' for amqp no auth.
# [*amqp_password*]
#   (optional) amqp password
#   Defaults to ''.
# [*rpc_backend*]
#   (optional) The rpc backend implementation to use.
#   Defaults to 'nova.openstack.common.rpc.impl_kombu'.
# [*verbose*]
#   (optional) Set log output to verbose output.
#   Defaults to 'false'.

class quickstack::nova (
  $admin_password,
  $auth_host          = 'localhost',
  $auto_assign_floating_ip = 'true',
  $bind_address       = '0.0.0.0',
  $db_host            = 'localhost',
  $db_name            = 'nova',
  $db_password,
  $db_user            = 'nova',
  $default_floating_pool,
  $force_dhcp_release = 'false',
  $glance_host        = 'localhost',
  $glance_port        = '9292',
  $image_service      = 'nova.image.glance.GlanceImageService',
  $memcached_servers  = 'false',
  $multi_host         = 'true',
  $neutron            = 'false',
  $neutron_metadata_proxy_secret,
  $qpid_heartbeat     = '60',
  $amqp_hostname      = 'localhost',
  $amqp_port          = '5672',
  $amqp_username      = '',
  $amqp_password      = '',
  $rpc_backend        = 'nova.openstack.common.rpc.impl_kombu',
  $verbose            = 'false',
) {

    # TODO: add ssl config here
    $nova_sql_connection = "mysql://${db_user}:${db_password}@${db_host}/${db_name}"
    $glance_api_uri =  "http://${glance_host}:${glance_port}/v1"

    class { '::nova':
      sql_connection => $nova_sql_connection, #bring over the ssl/not chunk from
      #    controller_common, that maybe should go in a function
      image_service      => $image_service,
      glance_api_servers => $glance_api_uri,
      memcached_servers  => $memcached_servers,
      rpc_backend        => $rpc_backend,
      verbose            => $verbose,
      qpid_port          => $amqp_port,
      qpid_hostname      => $amqp_hostname,
      qpid_heartbeat     => $qpid_heartbeat,
      qpid_username      => $amqp_username,
      qpid_password      => $amqp_password,
      rabbit_port        => $amqp_port,
      rabbit_host        => $amqp_hostname,
      rabbit_userid      => $amqp_username,
      rabbit_password    => $amqp_password,
    }

    nova_config { 'DEFAULT/default_floating_pool':
      value => $default_floating_pool;
    }

    if str2bool_i("$neutron") {
      class { '::nova::api':
        admin_password                       => $admin_password,
        api_bind_address                     => $bind_address,
        auth_host                            => $auth_host,
        enabled                              => true,
        neutron_metadata_proxy_shared_secret => $neutron_metadata_proxy_secret,
      }
    } else {

      nova_config {
        'DEFAULT/auto_assign_floating_ip': value => $auto_assign_floating_ip;
        'DEFAULT/multi_host':              value => $multi_host;
        'DEFAULT/force_dhcp_release':      value => $force_dhcp_release;
      }

      class { '::nova::api':
        enabled          => true,
        admin_password   => $admin_password,
        api_bind_address => $bind_address,
        auth_host        => $auth_host,
      }
    }
    class {'::nova::scheduler':
      enabled => true,
    }
    class {'::nova::cert':
      enabled => true,
    }
    class {'::nova::consoleauth':
      enabled => true,
    }
    class {'::nova::conductor':
      enabled => true,
    }

    class { '::nova::vncproxy':
      host    => $bind_address,
      enabled => true,
    }
    class {'::quickstack::firewall::nova':}
}
