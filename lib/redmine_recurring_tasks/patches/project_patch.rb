module RedmineRecurringTasks
  module Patches
    module ProjectPatch
      def self.included(base)
        base.class_eval do
          # A project has many recurring tasks through its issues
          has_many :recurring_tasks, through: :issues
        end
      end
    end
  end
end

# This line ensures the patch is applied to the Project model when this file is loaded.
Project.send(:include, RedmineRecurringTasks::Patches::ProjectPatch)
