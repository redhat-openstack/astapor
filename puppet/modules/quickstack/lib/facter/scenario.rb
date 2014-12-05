require 'facter'
require 'hiera'

hiera = Hiera.new
scenario = hiera.lookup('scenario', '', '')
scenarii = hiera.lookup('scenarii', '', '')

class Scene
  class << self
    def get_all_classes(roles)
      deps = []
      roles.each do |role|
        if scenarii[role]
          if scenarii[role]['roles']
            deps << Scene.get_all_classes(scenarii[role]['roles'])
          end
          if scenarii[role]['classes']
            deps << scenarii[role]['classes']
          end
        end
      end
      deps.flatten!.uniq! unless deps.empty?
      deps
    end

    def details(roles)
      classes = []
      classes << Scene.get_all_classes(roles) if roles
      classes.to_s
    end
  end
end

Facter.add("scenario_name") do
  setcode do
    scenario
  end
end

Facter.add("scenario_classes") do
  setcode do
    list = Scene.details(scenarii[scenario]['roles']) if scenarii[scenario]['roles']
    list.concat(scenarii[scenario]['classes']) if scenarii[scenario]['classes']
    list.flatten! unless list.empty?
  end
end
