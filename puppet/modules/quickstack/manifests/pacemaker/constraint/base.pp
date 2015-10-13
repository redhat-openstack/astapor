define quickstack::pacemaker::constraint::base (
  $constraint_type,
  $constraint_params=undef,
  $first_resource,
  $second_resource=undef,
  $first_action=undef,
  $second_action=undef,
  $location=undef,
  $score=undef,
  $ensure=present
) {
  include quickstack::pacemaker::params

  if has_interface_with("ipaddress", map_params("cluster_control_ip")){
    ::pacemaker::constraint::base{ "$name":
                                  constraint_type   => $constraint_type,
                                  constraint_params => $constraint_params,
                                  first_resource    => $first_resource,
                                  second_resource   => $second_resource,
                                  first_action      => $first_action,
                                  second_action     => $second_action,
                                  location          => $location,
                                  score             => $score,
                                  ensure            => $ensure}
  }
}
