class ProductsController < ApplicationController
  include Page
  self.page_size = 20
  
  skip_before_action :need_super_permission
  prepend_before_action :need_admin_permission, except: [:index, :show]
  before_action :need_level_3_permission, only: [:index, :show]
  before_action :set_product, only: [:show, :edit, :update, :destroy]

  # GET /products
  # GET /products.json
  def index
    @products = Product.limit(page_size).offset(offset(params[:page]))
    #@prev_page, @next_page = prev_and_next_page(params[:page], Product.count)
    @index = params[:page].to_i
    @index = 1 if @index <1
    @page_num = index_to_page(Product.count)
  end

  # GET /products/1
  # GET /products/1.json
  def show
    index = Product.where('created_at <= ?', @product.created_at).count
    @page = index_to_page(index)
  end

  # GET /products/new
  def new
    @product = Product.new
  end

  # GET /products/1/edit
  def edit
    if @product.state == State::STATE_SHADOW
      redirect_to products_url, notice: '已回收资源不允许编辑'
    end
  end

  # POST /products
  # POST /products.json
  def create
    @product = Product.new(product_params)

    respond_to do |format|
      if @product.save
        format.html { redirect_to @product, notice: '产品创建成功' }
        format.json { render :show, status: :created, location: @product }
      else
        format.html { render :new }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /products/1
  # PATCH/PUT /products/1.json
  def update
    respond_to do |format|
      if @product.update(product_params)
        format.html { redirect_to @product, notice: '产品更新成功' }
        format.json { render :show, status: :ok, location: @product }
      else
        format.html { render :edit }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /products/1
  # DELETE /products/1.json
  def destroy
    if @product.try_destroy
      message = '产品删除成功'
    else
      message = '产品资源已回收'
    end
    respond_to do |format|
      format.html { redirect_to products_url, notice: message }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product
      @product = Product.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def product_params
      params.require(:product).permit(:name)
    end
end
