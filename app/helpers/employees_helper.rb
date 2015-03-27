module EmployeesHelper
  def select_options_for_department
    Department.all.collect do |department|
      [department.name, department.id]
    end
  end

  def employee_options_all
    employee_map = []
    employee_map << ['全部', -1]
    employee_map += Employee.all.collect { |employee| [employee.name, employee.id] }
  end
end
