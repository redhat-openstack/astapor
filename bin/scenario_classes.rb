#!/bin/env ruby
require 'facter'
require 'hiera'

hiera = Hiera.new
scenario = ARGV[0]
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
      classes
    end
  end
end

list = Scene.details(SCENARII[scenario]['roles']) if SCENARII[scenario]['roles']
list.concat(SCENARII[scenario]['classes']) if SCENARII[scenario]['classes']
list.flatten! unless list.empty?
