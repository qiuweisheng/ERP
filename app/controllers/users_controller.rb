class UsersController < ApplicationController
  skip_before_action :need_super_permission
  before_action :need_admin_permission, only: [:index, :new, :create, :destroy]
  before_action :need_login, except: [:index, :new, :create, :destroy]
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  # GET /users
  # GET /users.json
  def index
    @users = User.all
  end

  # GET /users/1
  # GET /users/1.json
  def show
    check_permission
  end

  # GET /users/new
  def new
    @user = User.new
    @user.permission = 1
  end

  # GET /users/1/edit
  def edit
    check_permission
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    login_user = User.find(session[:user_id])
    if (login_user != @user && login_user.permission < @user.permission)
      @user.destroy
      msg = '成功删除'
    else
      msg = '权限不够'
    end
    respond_to do |format|
      format.html { redirect_to users_url, notice: msg }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:name, :password, :password_confirmation, :permission)
    end

    def check_permission
      # At this point, the user has already login
      login_user = User.find(session[:user_id])
      unless login_user == @user or [0, 1].include? login_user.permission
        redirect_to back_location(user_url(login_user)), notice: '帐户权限不够'
      end
    end
end
