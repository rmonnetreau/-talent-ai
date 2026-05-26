class ApplicationController < ActionController::Base
  before_action :set_interview, only: %i[show edit update]
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  def index
    @interviews = Interview.all
  end

  private

  def set_interview
    @interview = Interview.find(params[:id])
  end

  def interview_params
    params.require(:interview).permit(:job_title, :job_description)
  end
end
