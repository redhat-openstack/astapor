# just some syntatic sugar

define quickstack::pacemaker::constraint::typical(
  $constraint_type = 'order',
  $first_resource  = '',
  $second_resource = '',
  $first_action    = 'start',
  $second_action   = 'start',
  $colocation      = true,
) {

  quickstack::pacemaker::constraint::base { $title :
    constraint_type => $constraint_type,
    first_resource  => $first_resource,
    second_resource => $second_resource,
    first_action    => $first_action,
    second_action   => $second_action,
  }

  if $colocation {
    Quickstack::Pacemaker::Constraint::Base[$title] ->
    quickstack::pacemaker::constraint::colocation { "$title-colo" :
      source => $second_resource,
      target => $first_resource,
    }
  }
}
