require 'facter'
require 'hiera'

class Scene
  class << self
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

    def details(roles)
      classes = []
      classes << Scene.get_all_classes(roles) if roles
      classes
    end
  end
end

module Puppet::Parser::Functions
    newfunction(:scenario_classes, :type => :rvalue, :doc => <<-EOS
Returns unique list of all embedded class for a scenario
EOS
) do |arguments|
    Puppet::Parser::Functions.autoloader.loadall
    raise(Puppet::ParseError, "scenario_classes(): Wrong number of arguments " +
      "given (#{arguments.size} for 1)") if arguments.size < 1

    scenario = arguments[0] ||= false
    hiera = Hiera.new
    SCENARII = hiera.lookup('scenarii', '', '')

    list = Scene.details(SCENARII[scenario]['roles']) if SCENARII[scenario]['roles']
    list.concat(SCENARII[scenario]['classes']) if SCENARII[scenario]['classes']
    list.flatten! unless list.empty?
  end
end
