module Scenario
  class Scene
    class << self
      def get_all_classes(roles, scenarii)
        list = []
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
        list.flatten!.uniq! unless list.empty?
        list.delete_if {|x| x == nil }
        list
      end

      def all_classes(scenario, scenarii)
        list = []
        list = Scene.get_all_classes(scenarii[scenario]['roles'], scenarii) if scenarii[scenario]['roles']
        list << scenarii[scenario]['classes'] if scenarii[scenario]['classes']
        list.flatten! unless list.empty?
        list.uniq! unless list.empty?
        list
      end
    end
  end
end
