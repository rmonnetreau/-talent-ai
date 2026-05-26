class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: :home

  def home
    return unless current_user

    redirect_to interviews_path
  end
end
