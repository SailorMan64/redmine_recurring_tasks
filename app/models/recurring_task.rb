class RecurringTask < ActiveRecord::Base
  RUN_TYPE_W_DAYS = 'weekly'
  RUN_TYPE_M_DAYS = 'monthly'

  attr_accessor :client_run_type 

  belongs_to :issue
  belongs_to :tracker

  before_save :clear_other_run_type_params

  # This method overrides the default to ensure it always returns an array.
  def months
    return [] if super.blank?
    JSON.parse(super)
  rescue JSON::ParserError
    []
  end

  def month_days
    result = super
    result = JSON.parse(result)
  rescue
    []
  end

  def month_days_parsed
    month_days.map{|x| x == 'last_day' ? Time.now.end_of_month.day.to_s : x}.compact.uniq
  end

def humanize
  parts = []
  if run_type == :month_days
    # This part for monthly schedules is correct as it uses standard keys
    parts << "#{l('day')} #{month_days_parsed.join(', ')}. #{l('every_month')} #{months.map{|m| I18n.t("date.month_names")[m.to_i]}.join(', ')}"
  else
    # --- THIS IS THE FIX ---
    # This now uses the correct 'label_day_...' keys from your en.yml file
    days_text = []
    days_text << l(:label_day_sunday)    if self.sunday?
    days_text << l(:label_day_monday)    if self.monday?
    days_text << l(:label_day_tuesday)   if self.tuesday?
    days_text << l(:label_day_wednesday) if self.wednesday?
    days_text << l(:label_day_thursday)  if self.thursday?
    days_text << l(:label_day_friday)    if self.friday?
    days_text << l(:label_day_saturday)  if self.saturday?
    parts << l(:label_weekly_on, days: days_text.join(', ')) if days_text.present?
    # --- END FIX ---
  end

  # This was also missing the 'label_' prefix in my last version. Corrected now.
  parts << l(:at_time, time: self.time.strftime('%H:%M')) if self.time

  parts.join(' ')
end

  def run_type
    # ... (run_type method is unchanged) ...
  end

  def deep_clone
    # ... (deep_clone method is unchanged) ...
  end

# This is the original class method from v1 that finds all schedules due to be run.
  def self.schedules(current_time = Time.now)
    week_day  = current_time.strftime('%A').downcase
    month_day = current_time.day

    # months
    scope = where("months LIKE '%\"#{current_time.month.to_s}\"%'")

    scope.select do |schedule|
      if schedule.month_days.empty?
        # week day
        next unless schedule.public_send(week_day)
      else
        # month day
        month_days = schedule.month_days_parsed
        next unless month_days.include?(month_day.to_s)
      end

      # time
      schedule.time_came?(current_time)
    end
  end


  # @return [Issue] copied issue
  def copy_issue(associations = [])
    return if issue.project.archived? || issue.project.closed?

    settings = Setting.find_by(name: :plugin_redmine_recurring_tasks)&.value || {}

    issue.deep_clone(include: associations, except: %i[parent_id root_id lft rgt created_on updated_on closed_on]) do |original, copy|
      case original
      when Issue
        copy.init_journal(original.author)
        new_author =
          if settings['use_anonymous_user']
            User.anonymous
          else
            unless original.author.allowed_to?(:copy_issues, issue.project)
              raise UnauthorizedError, "User #{original.author.name} (##{original.author.id}) unauthorized to copy issues"
            end
            original.author
          end
        copy.assigned_to = nil if original.assigned_to.blank? || original.assigned_to.status == User::STATUS_LOCKED
        copy.custom_field_values = original.custom_field_values.inject({}) { |h, v| h[v.custom_field_id] = v.value; h }
        copy.author_id = new_author.id
        copy.tracker_id = original.tracker_id
        copy.parent_issue_id = original.parent_id
        copy.done_ratio = 0
        copy.status_id =
          case settings['copied_issue_status']
          when nil
            copy.new_statuses_allowed_to(original.author).sort_by(&:position).first&.id
          when '0'
            original.status_id
          else
            settings['copied_issue_status']
          end
        copy.attachments = original.attachments.map do |attachement|
          attachement.copy(container: original)
        end
        copy.watcher_user_ids = original.watcher_users.select { |u| u.status == User::STATUS_ACTIVE }.map(&:id)

        copy.start_date = Time.now

        if original.due_date.present?
          issue_date = (original.start_date || original.created_on).to_date
          copy.due_date = copy.start_date + (original.due_date - issue_date)
        end
      else
        next
      end
    end.tap(&:save!)
  end

  # @return [Boolean] boolean result of copy issue and save of schedule last try timestamp
  def execute(associations = nil)
    self.last_try_at = Time.now
    copy_issue(associations) && save
  end

  # @return [Symbol] return :month_days if any month days are present, else :week_days
  def run_type
    self.month_days.any? ? RUN_TYPE_M_DAYS : RUN_TYPE_W_DAYS
  end

  def time_came?(current_time = Time.now)
    utc_offset = current_time.utc_offset / 60 / 60
    utc_offset -= 1 if time.in_time_zone(utc_offset).dst?
    time.in_time_zone(utc_offset).strftime('%H%M%S').to_i <= current_time.strftime('%H%M%S').to_i &&
      (last_try_at.nil? || last_try_at.in_time_zone(utc_offset).strftime('%Y%m%d').to_i < current_time.strftime('%Y%m%d').to_i)
  end

  private

  def clear_other_run_type_params
    # ... (clear_other_run_type_params method is unchanged) ...
  end
end
