module EmployeesHelper
  def select_options_for_department
    options = []
    Department.all.each do |department|
      options << [department.name, department.id]
    end
    options
  end
end
