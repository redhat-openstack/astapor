class quickstack::pacemaker::base (
  ) inherits quickstack::pacemaker::params {

  include quickstack::pacemaker::common
  include quickstack::pacemaker::load_balancer
  include quickstack::pacemaker::galera
  include quickstack::pacemaker::qpid
  include quickstack::pacemaker::keystone
  include quickstack::pacemaker::swift
  include quickstack::pacemaker::glance
  include quickstack::pacemaker::nova
  include quickstack::pacemaker::cinder
  include quickstack::pacemaker::heat

  Class['::quickstack::pacemaker::common'] ->
  Class['::quickstack::pacemaker::load_balancer'] ->
  Class['::quickstack::pacemaker::galera'] ->
  Class['::quickstack::pacemaker::qpid'] ->
  Class['::quickstack::pacemaker::keystone'] ->
  Class['::quickstack::pacemaker::swift'] ->
  Class['::quickstack::pacemaker::glance'] ->
  Class['::quickstack::pacemaker::nova'] ->
  Class['::quickstack::pacemaker::cinder'] ->
  Class['::quickstack::pacemaker::heat']
}
