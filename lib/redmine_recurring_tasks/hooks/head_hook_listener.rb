module RedmineRecurringTasks
  module Hooks
    class HeadHookListener < Redmine::Hook::ViewListener
      # This tells Redmine to render our partial in the <head> of every page
      render_on :view_layouts_base_html_head, partial: 'recurring_tasks/head'
    end
  end
end
