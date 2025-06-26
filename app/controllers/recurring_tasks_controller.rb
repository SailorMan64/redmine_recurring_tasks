class RecurringTasksController < ApplicationController
  before_action :set_schedule, only: [:edit, :destroy, :update]
  before_action :set_issue, except: [:index]
  before_action :check_global_permission, only: [:index]
  before_action :check_project_permission, except: [:index]

  # Our new action to list all recurring tasks
  def index
    @schedules = RecurringTask.all.includes(issue: [:project, :tracker])
  end

  def new
    existing_schedule = RecurringTask.find_by(issue: @issue)
    if existing_schedule
      return redirect_to edit_recurring_task_path(existing_schedule)
    end
    @schedule = RecurringTask.new(issue_id: @issue.id, tracker_id: @issue.tracker_id)
  end

  def create
    @schedule = RecurringTask.new(issue: @issue, tracker_id: @issue.tracker_id)
    @schedule.assign_attributes(recurring_task_params)
    if @schedule.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to issue_path(@issue)
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @schedule.update(recurring_task_params)
      flash[:notice] = l(:notice_successful_update)
      redirect_to issue_path(@issue)
    else
      render :edit
    end
  end

  def destroy
    @schedule.destroy
    redirect_to issue_path(@issue)
  end

  private

  # --- All the necessary private methods are now included ---

  def recurring_task_params
    params.require(:recurring_task).permit(:sunday, :monday, :tuesday, :wednesday,
                                           :thursday, :friday, :saturday, :time,
                                           :client_run_type, months: [], month_days: [])
  end

  def set_schedule
    @schedule = RecurringTask.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def set_issue
    if @schedule.present?
      @issue = @schedule.issue
    else
      @issue = Issue.find(params[:issue_id])
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def check_global_permission
    raise ::Unauthorized unless User.current.allowed_to?(:view_recurring_tasks_list, nil, global: true)
  end

  def check_project_permission
    # Use the 'edit_schedule' permission as the base check
    unless User.current.allowed_to?(:edit_schedule, @issue.project)
      raise ::Unauthorized
    end
  end
end
