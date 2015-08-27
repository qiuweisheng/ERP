class RecordsController < ApplicationController
  include Page
  self.page_size = 20
  
  skip_before_action :need_super_permission
  prepend_before_action :need_admin_permission, only: [:show]
  prepend_before_action :need_login, only: [:index, :new, :create, :edit, :update, :destroy, :recent]
  before_action :check_for_account_user, only: [:new, :create, :recent]
  before_action :set_record, only: [:show, :edit, :update, :destroy]

  # GET /records
  # GET /records.json
  private def params_or_cookies()
    params[:from_date]   = cookies[:record_filter_from_date]   unless params[:from_date]
    params[:to_date]     = cookies[:record_filter_to_date]     unless params[:to_date]
    params[:record_type] = cookies[:record_filter_record_type] unless params[:record_type]
    params[:user_id]     = cookies[:record_filter_user_id]     unless params[:user_id]
    params[:product_id]  = cookies[:record_filter_product_id]  unless params[:product_id]
    params[:employee_id] = cookies[:record_filter_employee_id] unless params[:employee_id]
    params[:client_id]   = cookies[:record_filter_client_id]   unless params[:client_id]
    params[:particpant_type_id] = cookies[:record_filter_particpant_type_id]   unless params[:particpant_type_id]
    params[:order_number] = cookies[:record_filter_order_number]   unless params[:order_number]

    params[:record_type] = nil if params[:record_type] == '-1'
    params[:user_id]     = nil if params[:user_id] == '-1'
    params[:product_id]  = nil if params[:product_id] == '-1'
    params[:employee_id] = nil if params[:employee_id] == '-1'
    params[:client_id]   = nil if params[:client_id] == '-1'
    params[:particpant_type_id] = nil if params[:particpant_type_id] == ''
    params[:order_number] = nil if params[:order_number] == '*'

    cookies[:record_filter_from_date]   = params[:from_date]
    cookies[:record_filter_to_date]     = params[:to_date]
    cookies[:record_filter_record_type] = params[:record_type]
    cookies[:record_filter_user_id]     = params[:user_id]
    cookies[:record_filter_product_id]  = params[:product_id]
    cookies[:record_filter_employee_id] = params[:employee_id]
    cookies[:record_filter_client_id]   = params[:client_id]
    cookies[:record_filter_particpant_type_id] = params[:particpant_type_id]
    cookies[:record_filter_order_number] = params[:order_number]
  end

  def index
    if is_admin_permission?(session[:permission])
      @is_admin = true
    else
      @no_side_bar = true
      params[:user_id] = session[:user_id]
    end

    params_or_cookies()

    params[:from_date] ||= (Record.first.try(:date) || Time.now.to_date).strftime("%Y-%m-%d")
    params[:to_date] ||= Time.now.to_date.strftime("%Y-%m-%d")
    relations = Record.between_date(params[:from_date], params[:to_date])
    unless params[:user_id].blank?
      user = User.find(params[:user_id])
      relations = relations.where('user_id = ? OR (participant_id = ? AND participant_type = ?)', user, user, user.class.name)
    end
    unless params[:record_type].blank?
      relations = relations.of_type(params[:record_type])
    end
    if params[:particpant_type_id]
      particpant_type, particpant_id = params[:particpant_type_id].split('-')
      unless particpant_type.blank?
        relations = relations.where('participant_type = ? AND participant_id = ?', particpant_type, particpant_id.to_i)
      end
    end
    unless params[:product_id].blank?
      relations = relations.where('product_id = ?', params[:product_id])
    end
    unless params[:employee_id].blank?
      relations = relations.where('employee_id = ?', params[:employee_id])
    end
    unless params[:client_id].blank?
      relations = relations.where('client_id = ?', params[:client_id])
    end
    if params[:order_number]
      relations = relations.where('order_number = ?', params[:order_number])
    end
    @records = relations.order('updated_at DESC').limit(page_size).offset(offset(params[:page]))
    # @prev_page, @next_page = prev_and_next_page(params[:page], relations.count)
    @index = params[:page].to_i
    @index = 1 if @index <1
    @page_num = index_to_page(relations.count)
  end

  # GET /records/1
  # GET /records/1.json
  def show
    if is_admin_permission? session[:permission]
      index = Record.where('created_at >= ?', @record.created_at).count
    else
      index = Record.where('created_at >= ? and (user_id = ? OR (participant_id = ? AND participant_type = ?))', @record.created_at, session[:user_id], session[:user_id], User.name).count
    end
    @page = index_to_page(index)
  end

  # GET /records/new
  def new
    record = Record.find_by(id: params[:record])
    @record = record.try(:dup) || Record.new #Record.find_by(id: params[:record]).try(:dup) || Record.new
    @record.user_id = session[:user_id]
    @record.date = record.try(:date) || Time.now.to_date
    @record.weight = nil
    @record.count = nil
    @records = Record.where('user_id = ?', session[:user_id]).order('updated_at DESC').limit(page_size).all
    puts "!!!!!!!!!!!!!!!!!!#{@records.count}"
  end

  # GET /records/1/edit
  def edit
    index = Record.where('created_at >= ? and (user_id = ? OR (participant_id = ? AND participant_type = ?))', @record.created_at, session[:user_id], session[:user_id], User.name).count
    @page = index_to_page(index)
    if is_admin_permission?(session[:permission])
      return
    end
    if @record.user_id != session[:user_id]
      redirect_to records_url(page: @page), notice: '只能编辑本柜台创建的记录'
    end
  end

  # POST /records
  # POST /records.json
  def create
    @record = Record.new(record_params)

    respond_to do |format|
      if @record.save
        format.html { redirect_to new_record_url(record: @record), notice: '记录创建成功' }
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
    if session[:permission] > User::PERM_ADMIN and @record.user_id != session[:user_id]
      index = Record.where('created_at >= ? and (user_id = ? OR (participant_id = ? AND participant_type = ?))', @record.created_at, session[:user_id], session[:user_id], User.name).count
      redirect_to records_url(page: index_to_page(index)), notice: '只能更新本柜台创建的记录'
      return
    end

    respond_to do |format|
      if @record.update(record_params)
        format.html { redirect_to @record, notice: '记录更新成功' }
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
    if session[:permission] > User::PERM_ADMIN and @record.user_id != session[:user_id]
      index = Record.where('created_at >= ? and (user_id = ? OR (participant_id = ? AND participant_type = ?))', @record.created_at, session[:user_id], session[:user_id], User.name).count
      redirect_to records_url(page: index_to_page(index)), notice: '只能删除本柜台创建的记录'
      return
    end

    @record.destroy
    respond_to do |format|
      format.html { redirect_to records_url, notice: '记录删除成功' }
      format.json { head :no_content }
    end
  end

  #print
  def print
    require "reports_controller.rb"
    @printed_records = []
    ids = params[:ids]

    records = ids.map do |id|
      Record.find(id)
    end
    group = records.group_by do |r|
      r.participant.name
    end

    new_group = {}
    group.each do |key, val|
      new_group[key] = val.group_by do |r|
        r.user.name
      end
    end

    new_group.each do |name, val|
      val.each do |name2, val2|
        row = {
          col1: "组别:#{name}",
          col2: "柜台:#{name2}"
        }
        @printed_records.push(row)
        row = {
          col1: "时间:",
          col2: Time.now.strftime('%Y%m%d %H:%M:%S')
        }
        @printed_records.push(row)
        val2.each do |r|
          row = {
              col1: '摘要:',
              col2: r.product.try(:name)
          }
          @printed_records.push(row)
          title = case
                    when Record::DISPATCH.include?(r.record_type)
                      "交与重量:"
                    when Record::RECEIVE.include?(r.record_type)
                      "收回重量:"
                    else
                      "其他:"
                  end
          row = {
              col1: title,
              col2: r.weight
          }
          @printed_records.push(row)
        end
        row = {
          col1: "余额:",
          col2: val2[0].participant.balance_at_date(Time.now.to_date, val2[0].user)
        }
        @printed_records.push(row)
        @printed_records.push({col1: "====", col2: "===="})
      end
    end
    render layout: false
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_record
      @record = Record.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def record_params
      params.require(:record).permit(:date_text, :record_type, :product_text, :weight, :count, :user_id, :participant_text, :order_number, :employee_text, :client_text, :created_at, :updated_at)
    end
    
    def check_for_account_user
      if is_admin_permission? session[:permission]
        user = User.find(session[:user_id])
        redirect_to user_url(user), notice: '只有柜台帐户可以输入记录'
      else
        @no_side_bar = true
      end
    end 
end
