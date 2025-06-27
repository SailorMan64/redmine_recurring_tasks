class RecurringTask < ActiveRecord::Base
  UnauthorizedError = Class.new(StandardError)

  belongs_to :issue
  belongs_to :tracker

  validates :issue_id,   presence: true, uniqueness: true
  validates :tracker_id, presence: true
  validates :time,       presence: true

  DAYS = %w(monday tuesday wednesday thursday friday saturday sunday).freeze

  RUN_TYPE_W_DAYS = :week_days
  RUN_TYPE_M_DAYS = :month_days

  attr_accessor :client_run_type

  before_save do
    if client_run_type.present?
      if client_run_type == RUN_TYPE_M_DAYS.to_s
        DAYS.each{|d| public_send("#{d}=", false)}
      else
        self.month_days = []
      end
    end
  end

  # @return [Array<String>] array of days when schedule should be executed
  def days
    DAYS.select{|d| public_send(d)}
  end

  # --- START: Correct JSON parsing methods from original plugin ---
  def months=(value)
    value ||= default_months
    super(value.to_json)
  end

  def months
    JSON.parse(super) rescue []
  end

  def month_days=(value)
    value ||= default_month_days
    super(value.to_json)
  end

  def month_days
    JSON.parse(super) rescue []
  end
  # --- END: Correct JSON parsing methods ---

  def time=(value)
    value = Time.new(*value.values) if value.is_a?(Hash)
    return super(value.to_time) unless value.respond_to?(:utc)
    super(value.dup.utc)
  end

  def time
    super&.localtime
  end

  def month_days_parsed
    month_days.map{|x| x == 'last_day' ? Time.now.end_of_month.day.to_s : x}.compact.uniq
  end

  def self.schedules(current_time = Time.now)
    week_day  = current_time.strftime('%A').downcase
    month_day = current_time.day
    scope = where("months LIKE '%\"#{current_time.month.to_s}\"%'")
    scope.select do |schedule|
      if schedule.month_days.empty?
        next unless schedule.public_send(week_day)
      else
        month_days = schedule.month_days_parsed
        next unless month_days.include?(month_day.to_s)
      end
      schedule.time_came?(current_time)
    end
  end

  def copy_issue(associations = [])
    return if issue.project.archived? || issue.project.closed?
    settings = Setting.plugin_redmine_recurring_tasks || {}
    issue.deep_clone(include: associations, except: %i[parent_id root_id lft rgt created_on updated_on closed_on]) do |original, copy|
      if original.is_a?(Issue)
        copy.init_journal(original.author)
        new_author = settings['use_anonymous_user'] ? User.anonymous : original.author
        copy.author_id = new_author.id
        copy.tracker_id = self.tracker_id
        copy.parent_issue_id = original.parent_id
        copy.done_ratio = 0
        copy.status_id =
          case settings['copied_issue_status']
          when nil
            copy.new_statuses_allowed_to(new_author).sort_by(&:position).first&.id
          when '0'
            original.status_id
          else
            settings['copied_issue_status']
          end
        copy.start_date = Time.now
        if original.due_date.present?
          issue_date = (original.start_date || original.created_on).to_date
          copy.due_date = copy.start_date + (original.due_date - issue_date)
        end
        # Removed watcher & attachment logic for simplicity, can be added back if needed
      end
    end.tap(&:save!)
  end

  def execute(associations = nil)
    self.last_try_at = Time.now
    copy_issue(associations) && save
  end

  def run_type
    self.month_days.any? ? RUN_TYPE_M_DAYS : RUN_TYPE_W_DAYS
  end

  def time_came?(current_time = Time.now)
    utc_offset = current_time.utc_offset / 3600
    utc_offset -= 1 if time.in_time_zone(utc_offset).dst?
    time.in_time_zone(utc_offset).strftime('%H%M%S').to_i <= current_time.strftime('%H%M%S').to_i &&
      (last_try_at.nil? || last_try_at.in_time_zone(utc_offset).strftime('%Y%m%d').to_i < current_time.strftime('%Y%m%d').to_i)
  end

  # Our new method for the overview page
  def humanize
    parts = []

    if self.run_type == :month_days
    # This logic correctly formats monthly schedules
      day_list = self.month_days_parsed.join(', ')
      month_names_str = self.months.map { |m| I18n.t("date.month_names")[m.to_i] }.join(', ')
      parts << "#{l(:day)} #{day_list} #{l(:every_month)} #{month_names_str}"
    else
    # This logic correctly formats weekly schedules
      days_text = []
      days_text << l(:label_day_sunday)    if self.sunday?
      days_text << l(:label_day_monday)    if self.monday?
      days_text << l(:label_day_tuesday)   if self.tuesday?
      days_text << l(:label_day_wednesday) if self.wednesday?
      days_text << l(:label_day_thursday)  if self.thursday?
      days_text << l(:label_day_friday)    if self.friday?
      days_text << l(:label_day_saturday)  if self.saturday?

    # Manually construct the string instead of using a complex translation key
      parts << "Weekly on #{days_text.join(', ')}" if days_text.present?
    end

    # Append the time using the simple 'at_time' key
    parts << l(:at_time, time: self.time.strftime('%H:%M')) if self.time.present?
    parts.join(' ')
  end

  private

  def default_month_days
    []
  end

  def default_months
    (1..12).to_a.map(&:to_s)
  end
end
