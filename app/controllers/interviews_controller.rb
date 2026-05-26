class InterviewsController < ApplicationController
  before_action :set_interview, only: %i[show edit update destroy]

  def index
    @interviews = current_user.interviews.reverse
  end

  def show
  end

  def edit
  end

  def update
    @interview.update(interview_params)
    redirect_to interviews_path
  end

  def new
    @interview = Interview.new
  end

  def create
    @interview = Interview.new(interview_params)
    @interview.user = current_user
    if @interview.save
      redirect_to interviews_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @interview.destroy
    redirect_to interviews_path, status: :see_other, notice: "Entretien supprimé."
  end

  private

  def set_interview
    @interview = Interview.find(params[:id])
  end

  def interview_params
    params.require(:interview).permit(:job_title, :job_description)
  end
end
