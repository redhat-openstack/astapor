#!/bin/env ruby

require "hiera"
require "hiera/config"
require "hiera/scope"
require "/usr/share/openstack-puppet/modules/module-data/lib/hiera/backend/module_data_backend"
require '/usr/share/openstack-foreman-installer/puppet/modules/quickstack/lib/puppetx/redhat/scenario.rb'

class Hiera::Config
  class << self
    alias :old_load :load unless respond_to?(:old_load)

    def load(source)
      old_load(source)

      @config[:backends] << "module_data" unless @config[:backends].include?("module_data")

      @config
    end
  end
end

context = ARGV[0] ||= 'run'

case context
when 'dry'
  scenario = 'test'
  scenarii_test = {"compute"=>{"desc"=>"Nova Compute (no network)", "classes"=>["quickstack::compute_common"]}, "compute-neutron"=>{"desc"=>"Nova Compute, Neutron Network", "classes"=>["quickstack::neutron::nova"], "roles"=>["compute", "neutron-client-ML2-OVS"]}, "custom"=>{"desc"=>"Scenario from a list of classes and/or roles", "classes"=>["quickstack::compute_common"], "roles"=>[]}, "HA"=>{"desc"=>"HA Controllers (3+), Neutron Network agents", "classes"=>nil, "roles"=>["HA-controller", "neutron-network-agents", "PCS-neutron"]}, "HA-AIO"=>{"desc"=>"HA All in One (1), HA Controllers, Neutron network agents, Compute", "classes"=>["quickstack::compute_common"], "roles"=>["HA"]}, "HA-controller"=>{"desc"=>"HA Controllers (3+), No network", "classes"=>["quickstack::openstack_common", "quickstack::pacemaker::common", "quickstack::pacemaker::params", "quickstack::pacemaker::keystone", "quickstack::pacemaker::swift", "quickstack::pacemaker::load_balancer", "quickstack::pacemaker::memcached", "quickstack::pacemaker::qpid", "quickstack::pacemaker::rabbitmq", "quickstack::pacemaker::glance", "quickstack::pacemaker::nova", "quickstack::pacemaker::heat", "quickstack::pacemaker::cinder", "quickstack::pacemaker::horizon", "quickstack::pacemaker::galera"]}, "neutron-client-ML2-OVS"=>{"desc"=>"Neutron network layer, ML2 plugin, OVS agent", "classes"=>["quickstack::neutron", "quickstack::neutron::plugins::ml2", "quickstack::neutron::agents::ovs"]}, "neutron-network-agents"=>{"desc"=>"Neutron network agents", "classes"=>["quickstack::neutron::agents::dhcp", "quickstack::neutron::agents::l3", "quickstack::neutron::agents::lbass", "quickstack::neutron::services::fwaas"], "roles"=>["neutron-client-ML2-OVS"]}, "PCS-neutron"=>{"desc"=>"Pacemaker Neutron", "classes"=>["quickstack::pacemaker::neutron"], "roles"=>["neutron-client-ML2-OVS"]}, "legacy-controller-NHA"=>{"desc"=>"NHA Controller (1)", "classes"=>["quickstack::neutron::controller"]}, "legacy-ceutron-networker"=>{"desc"=>"Neutron Cliente Agents", "classes"=>["quickstack::neutron::networker"]}, "legacy-compute-neutron"=>{"desc"=>"Nova Compute, Neutron NHA client", "classes"=>["quickstack::neutron::compute"]}}
  result = Scenario.Scene.all_classes(scenario, scenarii)
  # result == [expected_test1]
  # using rspec lib for ^
when 'run'
  scenarii = Hiera.lookup('quickstack::params::scenarii')
  puts scenarii
  Scenario.Scene.all_classes(scenario, scenarii)
end
