define quickstack::pacemaker::resource::generic(
  $resource_name        = "${title}",
  $resource_params      = '',
  $resource_name_prefix = '',
  $meta_opts            = '',
  $operation_opts       = undef,
  $clone_opts           = undef,
  $group_opts           = undef,
  $resource_type        = "systemd",
  $tries                = 30,
  $try_sleep            = 6,
  $verify_on_create     = true,
  $post_success_sleep   = undef,
) {
  include quickstack::pacemaker::params

  if has_interface_with("ipaddress", map_params("cluster_control_ip")){

    if $resource_name != "" {
      $_resource_name = ":${resource_name_prefix}${resource_name}"
    } else {
      $_resource_name = ""
    }

    anchor { "qprs start $name": }
    ->
    pcmk_resource { $title:
      resource_type      => "${resource_type}${_resource_name}",
      resource_params    => $resource_params,
      meta_params        => $meta_opts,
      op_params          => $operation_opts,
      clone_params       => $clone_opts,
      group_params       => $group_opts,
      tries              => $tries,
      try_sleep          => $try_sleep,
      verify_on_create   => $verify_on_create,
      post_success_sleep => $post_success_sleep,
    }
    -> anchor { "qprs end ${title}": }
  }
}
