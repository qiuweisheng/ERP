class ContractorsController < ApplicationController
  include Page
  self.page_size = 20
  
  skip_before_action :need_super_permission
  prepend_before_action :need_admin_permission, except: [:index, :show]
  before_action :need_level_3_permission, only: [:index, :show]
  before_action :set_contractor, only: [:show, :edit, :update, :destroy]

  # GET /contractors
  # GET /contractors.json
  def index
    @contractors = Contractor.limit(page_size).offset(offset(params[:page]))
    @prev_page, @next_page = prev_and_next_page(params[:page], Contractor.count)
  end

  # GET /contractors/1
  # GET /contractors/1.json
  def show
    index = Contractor.where('created_at <= ?', @contractor.created_at).count
    @page = index_to_page(index)
  end

  # GET /contractors/new
  def new
    @contractor = Contractor.new
  end

  # GET /contractors/1/edit
  def edit
    if @contractor.state == State::STATE_SHADOW
      redirect_to contractors_url, notice: '已回收资源不允许编辑'
    end
  end

  # POST /contractors
  # POST /contractors.json
  def create
    @contractor = Contractor.new(contractor_params)

    respond_to do |format|
      if @contractor.save
        format.html { redirect_to @contractor, notice: '代工客户创建成功' }
        format.json { render :show, status: :created, location: @contractor }
      else
        format.html { render :new }
        format.json { render json: @contractor.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /contractors/1
  # PATCH/PUT /contractors/1.json
  def update
    respond_to do |format|
      if @contractor.update(contractor_params)
        format.html { redirect_to @contractor, notice: '代工客户更新成功' }
        format.json { render :show, status: :ok, location: @contractor }
      else
        format.html { render :edit }
        format.json { render json: @contractor.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /contractors/1
  # DELETE /contractors/1.json
  def destroy
    if @contractor.try_destroy
      message = '代工客户删除成功'
    else
      message = '代工客户资源已回收'
    end
    respond_to do |format|
      format.html { redirect_to contractors_url, notice: message }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_contractor
      @contractor = Contractor.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def contractor_params
      params.require(:contractor).permit(:name)
    end
end
