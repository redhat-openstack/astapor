define quickstack::pacemaker::constraint::generic (
  $constraint_type   = "order",
  $first_resource    = undef,
  $second_resource   = undef,
  $first_action      = undef,
  $second_action     = undef,
  $score             = undef,
  $constraint_params = undef,
  $tries             = '4',
) {
  include quickstack::pacemaker::params

  if has_interface_with("ipaddress", map_params("cluster_control_ip")){

    if $constraint_params != undef {
      $_constraint_params = "${constraint_params}"
    } else {
      $_constraint_params = ""
    }

    $pcs_command = "/usr/sbin/pcs constraint ${constraint_type} ${first_action} ${first_resource} then ${second_action} ${second_resource} ${_constraint_params}"

    anchor { "qpct start $name": }
    ->
    # We may need/want to set log level here?
    notify {"pcs command: ${title}":
      message => "running: ${pcs_command}",
    }
    ->
    exec {"create ${constraint_type} constraint ${title}":
      command   => $pcs_command,
      tries     => $tries,
      try_sleep => 30,
      unless    => "/usr/sbin/pcs constraint order show | grep ${first_resource} | grep ${second_resource}"
    }
    ->
    anchor { "qpct end ${title}": }
  }
}
