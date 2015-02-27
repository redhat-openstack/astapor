define quickstack::cinder::multi_instance_type (
  $index,
  $resource_prefix,
  $backend_names,
) {

  if $index >= 0 {
    $type_name = $backend_names[$index]

    # checking if already defined will allow multiple backend
    # instances to share the same backend name
    if ! defined(Cinder::Type["$type_name"]) {
      cinder::type { "$type_name":
        set_key   => 'volume_backend_name',
        set_value => $backend_names[$index],
      }
    }

    #recurse
    $next = $index - 1
    quickstack::cinder::multi_instance_type { "${resource_prefix}-${next}":
      index           => $next,
      resource_prefix => $resource_prefix,
      backend_names   => $backend_names,
    }
  }
}
