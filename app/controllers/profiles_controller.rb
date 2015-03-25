class ProfilesController < ApplicationController
  skip_before_action :need_super_permission
  prepend_before_action :need_admin_permission, except: [:index]
  before_action :need_level_3_permission, only: [:index]
  before_action :set_profile, only: [:edit, :update]

  # GET /profiles
  # GET /profiles.json
  def index
    Profile.create_if_needed('month_check_date', Profile::INTEGER_TYPE)
    Profile.create_if_needed('data_precision', Profile::INTEGER_TYPE)
    @profiles = Profile.all
  end

  # GET /profiles/1/edit
  def edit
  end

  # PATCH/PUT /profiles/1
  # PATCH/PUT /profiles/1.json
  def update
    respond_to do |format|
      if @profile.update(profile_params)
        format.html { redirect_to profiles_url, notice: '配置更新成功' }
      else
        format.html { render :edit }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_profile
      @profile = Profile.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def profile_params
      params.require(:profile).permit(:key, :value)
    end
end
