# define pacemaker constraints on haproxy, memcached, galera

define quickstack::pacemaker::constraint::base_services(
  $target_resource = '',
  $first_action    = 'start',
) {

  include quickstack::pacemaker::common

  quickstack::pacemaker::constraint::typical{ "haproxy-then-${target_resource}-constr" :
    first_resource  => "haproxy-clone",
    second_resource => $target_resource,
    colocation      => false,
  }
  quickstack::pacemaker::constraint::typical{ "memcached-then-${target_resource}-constr" :
    first_resource  => "memcached-clone",
    second_resource => $target_resource,
    colocation      => false,
  }
  if (str2bool_i(map_params('include_mysql'))) {
    quickstack::pacemaker::constraint::typical{ "galera-then-${target_resource}-constr" :
      first_resource  => "galera-master",
      second_resource => $target_resource,
      first_action    => $first_action,
      colocation      => false,
    }
  }
  if (str2bool_i(map_params('include_amqp'))) {
    if (map_params('amqp_provider') == 'rabbitmq') {
      quickstack::pacemaker::constraint::typical{ "rabbitmq-then-${target_resource}-constr" :
        first_resource  => "rabbitmq-server-clone",
        second_resource => $target_resource,
        colocation      => false,
      }
    } else {
      quickstack::pacemaker::constraint::typical{ "qpidd-then-${target_resource}-constr" :
        first_resource  => "qpidd-clone",
        second_resource => $target_resource,
        colocation      => false,
      }
    }
  }
}
