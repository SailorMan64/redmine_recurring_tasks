# This loads all the patches and hooks, including our restored issue_patch.rb
reloader = defined?(ActiveSupport::Reloader) ? ActiveSupport::Reloader : ActionDispatch::Reloader
reloader.to_prepare do
  paths = '/lib/redmine_recurring_tasks/{patches/*_patch,hooks/*_hook}.rb'
  Dir.glob(File.dirname(__FILE__) + paths).each do |file|
    require_dependency file
  end
end

Redmine::Plugin.register :redmine_recurring_tasks do
  name 'Redmine Recurring Tasks'
  author 'Southbridge'
  description 'Plugin for creating scheduled tasks from template'
  version '0.4.0'
  requires_redmine version_or_higher: '5.1'

  settings default: { #... your settings ...
  }, partial: 'settings/redmine_recurring_tasks'

  # Add the new permission for our list page
  #permission :view_recurring_tasks_list, { recurring_tasks: :index }, require: :loggedin
  permission :view_recurring_tasks_list, { recurring_tasks: :index }, project_module: :redmine_recurring_tasks, require: :loggedin
  project_module :redmine_recurring_tasks do
    permission :view_schedule,   recurring_tasks: :show, read: true
    permission :edit_schedule,   recurring_tasks: [:edit, :update], require: :loggedin
    permission :manage_schedule, recurring_tasks: [:new, :create, :destroy, :update], require: :loggedin
  end

  # Add the new project menu item
     menu :project_menu, :recurring_tasks, { controller: 'recurring_tasks', action: 'index' },
     caption: 'Recurring Tasks',
     after: :settings, # A good place for it is after the project "Settings" tab
     param: :project_id # This is the crucial part
end
