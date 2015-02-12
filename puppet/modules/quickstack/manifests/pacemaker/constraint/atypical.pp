# just some syntatic sugar

define quickstack::pacemaker::constraint::atypical(
  $first_resource  = '',
  $second_resource = '',
  $colocation      = true,
) {

  quickstack::pacemaker::constraint::generic { $title :
    constraint_type   => "order",
    first_resource    => $first_resource,
    second_resource   => $second_resource,
    first_action      => "start",
    second_action     => "start",
    constraint_params => "kind=Optional",
  }

  if $colocation {
    Quickstack::Pacemaker::Constraint::Generic[$title] ->
    quickstack::pacemaker::constraint::colocation { "$title-colo" :
      source => $first_resource,
      target => $second_resource,
    }
  }
}
