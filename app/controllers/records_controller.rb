class RecordsController < ApplicationController  
  skip_before_action :need_super_permission
  prepend_before_action :need_admin_permission, only: [:edit, :show, :update, :destroy]
  prepend_before_action :need_login, only: [:index, :new, :create, :recent]
  before_action :check_for_account_user, only: [:new, :create, :recent]
  before_action :set_record, only: [:show, :edit, :update, :destroy]

  # GET /records
  # GET /records.json
  def index
    page_size = 20
    page_num = (params[:page] || 1).to_i
    if [User::PERM_SUPER, User::PERM_ADMIN].include? session[:permission]
      @is_admin = true
      page_total = (Record.count + page_size) / page_size
      @records = Record.order('created_at DESC').limit(page_size).offset((page_num - 1) * page_size)
    else
      @no_side_bar = true
      page_total = (Record.where(user_id: session[:user_id]).count + page_size) / page_size
      @records = Record.where(user_id: session[:user_id]).order('created_at DESC').limit(page_size).offset((page_num - 1) * page_size)
    end
    if page_num > 1
      @prev_page = page_num - 1
    end
    if page_num < page_total
      @next_page = page_num + 1
    end
  end

  # GET /records/1
  # GET /records/1.json
  def show
  end

  # GET /records/new
  def new
    @record = Record.find_by(id: params[:record]) || Record.new
    @record.user_id = session[:user_id]
    @record.date = Time.now.to_date
  end

  # GET /records/1/edit
  def edit
  end

  # POST /records
  # POST /records.json
  def create
    @record = Record.new(record_params)

    respond_to do |format|
      if @record.save
        format.html { redirect_to records_url, notice: '记录创建成功' }
        format.json { render :show, status: :created, location: @record }
      else
        format.html { render :new }
        format.json { render json: @record.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /records/1
  # PATCH/PUT /records/1.json
  def update
    respond_to do |format|
      if @record.update(record_params)
        format.html { redirect_to @record, notice: 'Record was successfully updated.' }
        format.json { render :show, status: :ok, location: @record }
      else
        format.html { render :edit }
        format.json { render json: @record.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /records/1
  # DELETE /records/1.json
  def destroy
    @record.destroy
    respond_to do |format|
      format.html { redirect_to records_url, notice: 'Record was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_record
      @record = Record.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def record_params
      params.require(:record).permit(:date_text, :record_type, :product_text, :weight, :count, :user_id, :participant_text, :order_number, :employee_text, :client_text)
    end
    
    def check_for_account_user
      if [User::PERM_SUPER, User::PERM_ADMIN].include? session[:permission]
        user = User.find(session[:user_id])
        redirect_to user_url(user), notice: '只有柜台帐户可以输入记录'
      else
        @no_side_bar = true
      end
    end 
end
