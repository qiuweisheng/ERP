require 'test_helper'

class EmployeeTest < ActiveSupport::TestCase
  setup do
    @attrs = {
        name: '陈祖业',
        department_id: 0
    }
  end

  test 'serial_number should be generated automatically on creation' do
    employee = Employee.new @attrs
    employee.save
    assert_equal employees(:two).serial_number + 1, employee.serial_number

    Employee.delete_all
    (Employee::MIN_ID..Employee::MAX_ID).each do
      employee = Employee.new @attrs
      employee.save
    end
    employee = Employee.first
    old_id = employee.serial_number
    employee.destroy
    employee = Employee.new @attrs
    employee.save
    assert_equal old_id, employee.serial_number
  end

  test 'serial_number should not exceed maximum id' do
    Employee.delete_all
    (Employee::MIN_ID..Employee::MAX_ID).each do
      employee = Employee.new @attrs
      employee.save
    end
    employee = Employee.new @attrs
    assert employee.invalid?
    assert_includes employee.errors[:serial_number], "帐户达到最大值:#{Employee::MAX_ID}"
  end

  test 'serial_number should not change on update' do
    employee = employees(:one)
    old_id = employee.serial_number
    employee.serial_number += 1
    employee.save
    assert_equal old_id, employee.serial_number
  end

  test 'name should be present' do
    employee = Employee.new @attrs
    employee.name = nil
    assert employee.invalid?
  end

  test 'department_id should be present' do
    employee = Employee.new @attrs
    employee.department_id = nil
    assert employee.invalid?
  end
end
