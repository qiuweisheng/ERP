class EmployeesController < ApplicationController
  include Page
  self.page_size = 20
  
  skip_before_action :need_super_permission
  prepend_before_action :need_admin_permission
  before_action :set_employee, only: [:show, :edit, :update, :destroy]

  # GET /employees
  # GET /employees.json
  def index
    @employees = Employee.limit(page_size).offset(offset(params[:page]))
    @prev_page, @next_page = prev_and_next_page(params[:page], Client.count)
  end

  # GET /employees/1
  # GET /employees/1.json
  def show
    index = Employee.where('created_at <= ?', @employee.created_at).count
    @page = index_to_page(index)
  end

  # GET /employees/new
  def new
    @employee = Employee.new
  end

  # GET /employees/1/edit
  def edit
    if @employee.state == State::STATE_SHADOW
      redirect_to employees_url, notice: '已回收资源不允许编辑'
    end
  end

  # POST /employees
  # POST /employees.json
  def create
    @employee = Employee.new(employee_params)

    respond_to do |format|
      if @employee.save
        format.html { redirect_to @employee, notice: '员工创建成功' }
        format.json { render :show, status: :created, location: @employee }
      else
        format.html { render :new }
        format.json { render json: @employee.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /employees/1
  # PATCH/PUT /employees/1.json
  def update
    respond_to do |format|
      if @employee.update(employee_params)
        format.html { redirect_to @employee, notice: '员工更新成功' }
        format.json { render :show, status: :ok, location: @employee }
      else
        format.html { render :edit }
        format.json { render json: @employee.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /employees/1
  # DELETE /employees/1.json
  def destroy
    if @employee.try_destroy
      message = '员工删除成功'
    else
      message = '员工资源已回收'
    end
    respond_to do |format|
      format.html { redirect_to employees_url, notice: message }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_employee
      @employee = Employee.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def employee_params
      params.require(:employee).permit(:name, :department_id, :colleague_count)
    end
end
