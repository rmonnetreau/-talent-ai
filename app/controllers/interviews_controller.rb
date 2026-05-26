class InterviewsController < ApplicationController
  before_action :set_interview, only: %i[show edit update]

  def index
    @interviews = current_user.interviews
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
      redirect_to interview_path(@interview)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_interview
    @interview = Interview.find(params[:id])
  end

  def interview_params
    params.require(:interview).permit(:job_title, :job_description)
  end
end
