require 'facter'
require 'hiera'

hiera = Hiera.new
SCENARIO = hiera.lookup('scenario', '', '')
SCENARII = hiera.lookup('scenarii', '', '')

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
      classes.to_s
    end
  end
end

Facter.add("scenario_classes") do
  setcode do
    list = Scene.details(SCENARII[SCENARIO]['roles']) if SCENARII[SCENARIO]['roles']
    list.concat(SCENARII[SCENARIO]['classes']) if SCENARII[SCENARIO]['classes']
    list.flatten! unless list.empty?
  end
end
