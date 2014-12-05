def get_all_classes(roles, scenarii)
  deps = []
  roles.each do |role|
    if scenarii[role]
      if scenarii[role]['roles']
        deps << get_all_classes(scenarii[role]['roles'], scenarii)
      end
      if scenarii[role]['classes']
        deps << scenarii[role]['classes']
      end
    end
  end
  deps.flatten!.uniq! unless deps.empty?
  p deps
  deps
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
    scenarii = arguments[1] ||= []
    raise(Puppet::ParseError, "Missing argumets") if scenario.empty? || scenarii.empty?

    list = get_all_classes(scenarii[scenario]['roles'], scenarii) if scenarii[scenario]['roles']
    p list
    list.concat(scenarii[scenario]['classes']) if scenarii[scenario]['classes']
    list.flatten! unless list.empty?
  end
end
