class UsersController < ApplicationController
  include Page
  self.page_size = 20
  
  skip_before_action :need_super_permission
  prepend_before_action :need_admin_permission, only: [:index, :new, :create, :destroy]
  prepend_before_action :need_login, only: [:show, :edit]
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :check_for_admin_or_login_user, only: [:show, :edit]

  # GET /users
  # GET /users.json
  def index
    @users = User.limit(page_size).offset(offset(params[:page]))
    @prev_page, @next_page = prev_and_next_page(params[:page], User.count)
  end

  # GET /users/1
  # GET /users/1.json
  def show
    index = User.where('created_at <= ?', @user.created_at).count
    @page = index_to_page(index)
  end

  # GET /users/new
  def new
    @user = User.new
    @user.permission = 1
  end

  # GET /users/1/edit
  def edit
    if @user.state == State::STATE_SHADOW
      redirect_to users_url, notice: '已回收资源不允许编辑'
    end
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: '用户创建成功' }
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
        format.html { redirect_to @user, notice: '用户更新成功' }
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
    # Can not delete himself
    if (login_user != @user && login_user.permission < @user.permission)
      if @user.try_destroy
        message = '用户删除成功'
      else
        message = '用户资源已回收'
      end
    else
      message = '权限不够'
    end
    respond_to do |format|
      format.html { redirect_to users_url, notice: message }
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

    def check_for_admin_or_login_user
      # At this point, the user has already login
      login_user = User.find(session[:user_id])
      unless login_user == @user or is_admin_permission? login_user.permission
        redirect_to_main_page login_user, notice: '帐户权限不够'
      end
    end
end
