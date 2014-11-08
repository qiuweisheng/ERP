module EmployeesHelper
  def select_options_for_department
    Department.all.collect do |department|
      [department.name, department.id]
    end
  end
end
