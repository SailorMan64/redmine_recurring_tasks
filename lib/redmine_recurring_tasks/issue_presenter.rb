module RedmineRecurringTasks
  class IssuePresenter
    # --- THIS IS THE FIX ---
    # Include necessary helpers to get access to methods like l() and format_time()
    include I18n
    include Redmine::I18n
    # --- END FIX ---

    attr_reader :issue

    def initialize(issue)
      @issue = issue
    end

    def schedule
      return '' unless issue.recurring_task.present?
      if issue.recurring_task.run_type == RecurringTask::RUN_TYPE_M_DAYS
        "#{l('day')} #{issue.recurring_task.month_days_parsed.join(', ')}. #{l('every_month')} #{issue.recurring_task.months.map{|m| I18n.t("date.month_names")[m.to_i]}.join(', ')}"
##        "#{l('day')} #{issue.recurring_task.month_days_parsed.join(', ')}. #{l('every_month')} #{issue.recurring_task.months_parsed.join(', ')}"
      else
        days = []
        days << l(:label_day_sunday)    if issue.recurring_task.sunday?
        days << l(:label_day_monday)    if issue.recurring_task.monday?
        days << l(:label_day_tuesday)   if issue.recurring_task.tuesday?
        days << l(:label_day_wednesday) if issue.recurring_task.wednesday?
        days << l(:label_day_thursday)  if issue.recurring_task.thursday?
        days << l(:label_day_friday)    if issue.recurring_task.friday?
        days << l(:label_day_saturday)  if issue.recurring_task.saturday?
        days.join(', ')
      end
    end

    def schedule_template
      return '' unless issue.recurring_task.present? && issue.recurring_task.time.present?
      "#{l('at_time', time: issue.recurring_task.time.strftime('%H:%M'))}"
    end
  end
end
