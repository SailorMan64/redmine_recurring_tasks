module RedmineRecurringTasks
  module Patches
    module IssuePatch
      def self.included(base) # :nodoc:
        base.class_eval do
          has_one :recurring_task, dependent: :destroy

          # Return parent issue of children
          def recurring_task_root
            return recurring_task if recurring_task

            RecurringTask.joins(:issue).find_by(issues: {
              subject:    subject,
              project_id: project_id,
              author_id:  author_id
            })
          end
        end
      end
    end
  end
end
# This line at the bottom is crucial - it applies the patch automatically.
Issue.send(:include, RedmineRecurringTasks::Patches::IssuePatch)
