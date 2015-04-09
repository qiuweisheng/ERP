class ClientsController < ApplicationController
  include Page
  self.page_size = 20
  
  skip_before_action :need_super_permission
  prepend_before_action :need_admin_permission, except: [:index, :show]
  before_action :need_level_3_permission, only: [:index, :show]
  before_action :set_client, only: [:show, :edit, :update, :destroy]

  # GET /clients
  # GET /clients.json
  def index
    @clients = Client.limit(page_size).offset(offset(params[:page]))
    #@prev_page, @next_page = prev_and_next_page(params[:page], Client.count)
    @index = params[:page].to_i
    @index = 1 if @index <1
    @page_num = index_to_page(Client.count)
  end

  # GET /clients/1
  # GET /clients/1.json
  def show
    index = Client.where('created_at <= ?', @client.created_at).count
    @page = index_to_page(index)
  end

  # GET /clients/new
  def new
    @client = Client.new
  end

  # GET /clients/1/edit
  def edit
    if @client.state == State::STATE_SHADOW
      redirect_to clients_url, notice: '已回收资源不允许编辑'
    end
  end

  # POST /clients
  # POST /clients.json
  def create
    @client = Client.new(client_params)

    respond_to do |format|
      if @client.save
        format.html { redirect_to @client, notice: '客户创建成功' }
        format.json { render :show, status: :created, location: @client }
      else
        format.html { render :new }
        format.json { render json: @client.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /clients/1
  # PATCH/PUT /clients/1.json
  def update
    respond_to do |format|
      if @client.update(client_params)
        format.html { redirect_to @client, notice: '客户更新成功' }
        format.json { render :show, status: :ok, location: @client }
      else
        format.html { render :edit }
        format.json { render json: @client.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /clients/1
  # DELETE /clients/1.json
  def destroy
    if @client.try_destroy
      message = '客户删除成功'
    else
      message = '客户资源已回收'
    end
    respond_to do |format|
      format.html { redirect_to clients_url, notice: message }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_client
      @client = Client.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def client_params
      params.require(:client).permit(:name)
    end
end
