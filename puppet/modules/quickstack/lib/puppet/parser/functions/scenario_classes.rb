class Scene
  class << self
    def get_all_classes(roles, scenarii)
      list = Array.new
      roles.each do |role|
        if scenarii[role]
          if scenarii[role]['roles']
            list << Scene.get_all_classes(scenarii[role]['roles'], scenarii)
          end
          if scenarii[role]['classes']
            list << scenarii[role]['classes']
          end
        end
      end
      list
      # deps.flatten!.uniq! unless deps.empty?
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
      "given (#{arguments.size} for 2)") if arguments.size < 2

    scenario = arguments[0] ||= ''
    scenarii = arguments[1] ||= {}
p scenarii.class
    raise(Puppet::ParseError, "Missing argumets") if scenario.empty? || scenarii.empty?

    list = []
    list = get_all_classes(scenarii[scenario]['roles'], scenarii) if scenarii[scenario]['roles']
    list << scenarii[scenario]['classes'] if scenarii[scenario]['classes']
    p list
    list.flatten! unless list.empty?
    list
  end
end
