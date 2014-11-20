class RecordsController < ApplicationController
  skip_before_action :need_super_permission
  before_action :set_record, only: [:show, :edit, :update, :destroy]

  # GET /records
  # GET /records.json
  def index
    @records = Record.all
  end

  # GET /records/1
  # GET /records/1.json
  def show
  end

  # GET /records/new
  # type: 'normal', 'check', 'polish', 'package', 'weight_difference' 
  def new
    @record = Record.new date: Time.now.to_date, count: 0
    @type = params[:type]
    redirect_to(recent_records_url) unless set_title_and_partial(@type)
  end

  # GET /records/1/edit
  def edit
  end

  # POST /records
  # POST /records.json
  def create
    @record = Record.new(record_params)
    @type = params[:type]
    set_title_and_partial @type

    respond_to do |format|
      if @record.save
        format.html { redirect_to recent_records_url, notice: '记录创建成功' }
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

  def recent
    @no_side_bar = true
    @records = Record.where(user_id: session[:user_id]).order('created_at DESC').first(18)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_record
      @record = Record.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def record_params
      params.require(:record).permit(:date_text, :type_text, :product_text, :weight, :count, :user_text, :participant_text, :order_number, :employee_text, :client_text)
    end
    
    def set_title_and_partial(type)
      case type
      when 'normal'
        @title = '收发记录'
        @partial = 'normal_form'
      when 'check'
        @title = '盘点记录'
        @partial = 'check_form'
      when 'polish'
        @title = '打磨记录'
        @partial = 'form'
      when 'package'
        @title = '包装记录'
        @partial = 'package_form'
      when 'weight_difference'
        @title = '客户称差记录'
        @partial = 'difference_form'
      else
        false
      end
    end
end
