require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppetx', 'redhat', 'scenario.rb'))

# Puppet::Parser::Functions.autoloader.loadall

load '/usr/share/openstack-foreman-installer/lib/scenario'

module Puppet::Parser::Functions

newfunction(:scenario_classes, :type => :rvalue, :doc => <<-EOS
Returns unique list of all embedded class for a scenario
EOS
) do |arguments|
    Puppet::Parser::Functions.autoloader.loadall
    raise(Puppet::ParseError, "scenario_classes(): Wrong number of arguments " +
      "given (#{arguments.size} for 2)") if arguments.size < 2

    scenario = arguments[0] ||= ''
    scenarii = arguments[1] ||= {}
    raise(Puppet::ParseError, "Missing argumets") if scenario.empty? || scenarii.empty?

    Scenario.Scene.all_classes(scenario, scenarii)
  end
end
