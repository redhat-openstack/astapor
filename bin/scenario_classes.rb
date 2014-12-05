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
  end
end

deps=[]
deps << Scene.get_all_classes(SCENARII[scenario]['roles']) if SCENARII[scenario]['roles']
deps << SCENARII[scenario]['classes'] if SCENARII[scenario]['classes']
p deps
deps.flatten! unless deps.empty?
deps
