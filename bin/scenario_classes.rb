#!/bin/env ruby
hiera = Hiera.new
scenario = ARGV[0]
SCENARII = {"scenarii"=>{"compute"=>{"desc"=>"Nova Compute (no network)", "classes"=>["quickstack::compute_common"]}, "compute-neutron"=>{"desc"=>"Nova Compute, Neutron Network", "classes"=>["quickstack::neutron::nova"], "roles"=>["compute", "neutron-client-ML2-OVS"]}, "custom"=>{"desc"=>"Scenario from a list of classes and/or roles", "classes"=>["quickstack::compute_common"], "roles"=>[]}, "HA"=>{"desc"=>"HA Controllers (3+), Neutron Network agents", "classes"=>nil, "roles"=>["HA-controller", "neutron-network-agents", "PCS-neutron"]}, "HA-AIO"=>{"desc"=>"HA All in One (1), HA Controllers, Neutron network agents, Compute", "classes"=>["quickstack::compute_common"], "roles"=>["HA"]}, "HA-controller"=>{"desc"=>"HA Controllers (3+), No network", "classes"=>["quickstack::openstack_common", "quickstack::pacemaker::common", "quickstack::pacemaker::params", "quickstack::pacemaker::keystone", "quickstack::pacemaker::swift", "quickstack::pacemaker::load_balancer", "quickstack::pacemaker::memcached", "quickstack::pacemaker::qpid", "quickstack::pacemaker::rabbitmq", "quickstack::pacemaker::glance", "quickstack::pacemaker::nova", "quickstack::pacemaker::heat", "quickstack::pacemaker::cinder", "quickstack::pacemaker::horizon", "quickstack::pacemaker::galera"]}, "neutron-client-ML2-OVS"=>{"desc"=>"Neutron network layer, ML2 plugin, OVS agent", "classes"=>["quickstack::neutron", "quickstack::neutron::plugins::ml2", "quickstack::neutron::agents::ovs"]}, "neutron-network-agents"=>{"desc"=>"Neutron network agents", "classes"=>["quickstack::neutron::agents::dhcp", "quickstack::neutron::agents::l3", "quickstack::neutron::agents::lbass", "quickstack::neutron::services::fwaas"], "roles"=>["neutron-client-ML2-OVS"]}, "PCS-neutron"=>{"desc"=>"Pacemaker Neutron", "classes"=>["quickstack::pacemaker::neutron"], "roles"=>["neutron-client-ML2-OVS"]}, "legacy-controller-NHA"=>{"desc"=>"NHA Controller (1)", "classes"=>["quickstack::neutron::controller"]}, "legacy-ceutron-networker"=>{"desc"=>"Neutron Cliente Agents", "classes"=>["quickstack::neutron::networker"]}, "legacy-compute-neutron"=>{"desc"=>"Nova Compute, Neutron NHA client", "classes"=>["quickstack::neutron::compute"]}}

def get_all_classes(roles)
  deps = []
  roles.each do |role|
    if SCENARII[role]
      if SCENARII[role]['roles']
        deps << Scene.get_all_classes(SCENARII[role]['roles'])
      end
      if SCENARII[role]['classes']
        deps << SCENARII[role]['classes']
      end
    end
  end
  deps.flatten!.uniq! unless deps.empty?
  deps
end

deps=[]
deps << get_all_classes(SCENARII[scenario]['roles']) if SCENARII[scenario]['roles']
deps << SCENARII[scenario]['classes'] if SCENARII[scenario]['classes']
p deps
deps.flatten! unless deps.empty?
deps
