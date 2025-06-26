class RecurringTask < ActiveRecord::Base
  RUN_TYPE_W_DAYS = 'weekly'
  RUN_TYPE_M_DAYS = 'monthly'

  attr_accessor :client_run_type 

  belongs_to :issue
  belongs_to :tracker

  before_save :clear_other_run_type_params

  # --- FIX: Add methods to parse JSON strings into arrays ---
  def months_parsed
    return [] if months.blank?
    JSON.parse(months)
  rescue JSON::ParserError
    []
  end

  def month_days_parsed
    return [] if month_days.blank?
    JSON.parse(month_days)
  rescue JSON::ParserError
    []
  end
  # --- END FIX ---

  def humanize
    # ... (humanize method is unchanged) ...
  end

  def run_type
    # ... (run_type method is unchanged) ...
  end

  def deep_clone
    # ... (deep_clone method is unchanged) ...
  end

  private

  def clear_other_run_type_params
    # ... (clear_other_run_type_params method is unchanged) ...
  end
end
