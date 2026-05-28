class ProfilesController < ApplicationController
  before_action :set_profile, only: %i[show edit update]

  def show
    return if @profile

    redirect_to new_profile_path, notice: "Please create your profile first."
  end

  def new
    @profile = current_user.build_profile
  end

  def edit
    return if @profile

    redirect_to new_profile_path, alert: "Please create your profile first."
  end

  def create
    @profile = current_user.build_profile(profile_params)

    if @profile.save
      redirect_to profile_path, notice: "Profile created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @profile&.update(profile_params)
      redirect_to profile_path, notice: "Profile updated successfully."
    elsif @profile.nil?
      redirect_to new_profile_path, alert: "Please create your profile first."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_profile
    @profile = current_user.profile
  end

  def profile_params
    params.require(:profile).permit(:first_name, :last_name, :cv)
  end
end
