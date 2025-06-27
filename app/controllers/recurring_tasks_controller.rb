class RecurringTasksController < ApplicationController
  # These filters now run in the correct order for all actions
  before_action :find_project
  before_action :set_schedule, only: [:edit, :update, :destroy]
  before_action :find_issue_from_params, only: [:new, :create]
  before_action :authorize

  def index
  # Get the IDs of the current project and all its descendants
  project_ids = @project.self_and_descendants.pluck(:id)

  # Find all recurring tasks where the associated issue's project_id is in our list
  @schedules = RecurringTask.joins(:issue)
                            .where(issues: { project_id: project_ids })
                            .order('issues.id DESC')
  end

  def new
    @schedule = @project.recurring_tasks.new(issue: @issue, tracker_id: @issue.tracker_id)
  end

  def create
    @schedule = @project.recurring_tasks.new(issue: @issue)
    @schedule.assign_attributes(recurring_task_params)
    if @schedule.save
      redirect_to issue_path(@issue)
    else
      render :new
    end
  end

  def edit
    # Make sure @issue is set for the form to use
    @issue = @schedule.issue
  end

  def update
    if @schedule.update(recurring_task_params)
      redirect_to issue_path(@schedule.issue)
    else
      @issue = @schedule.issue # Reload @issue if rendering edit again
      render :edit
    end
  end

  def destroy
    @schedule.destroy
    redirect_to project_recurring_tasks_path(@project)
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def set_schedule
    @schedule = @project.recurring_tasks.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_issue_from_params
    @issue = @project.issues.find(params[:issue_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def recurring_task_params
    params.require(:recurring_task).permit!
  end
end
