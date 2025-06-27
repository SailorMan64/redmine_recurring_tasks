module RedmineRecurringTasks
  class IssuePresenter < SimpleDelegator
    include I18n
    include Redmine::I18n

    attr_reader :issue

    def initialize(issue)
      @issue = issue
    end

    def schedule
    # This now just calls our single, definitive method from the model.
      issue.recurring_task&.humanize
    end

    def schedule_template
      return '' unless issue.recurring_task.present? && issue.recurring_task.time.present?
      "#{l('at_time', time: issue.recurring_task.time.strftime('%H:%M'))}"
    end
  end
end
