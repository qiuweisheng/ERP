require 'test_helper'

class EmployeeTest < ActiveSupport::TestCase
  setup do
    @attrs = { name: '陈祖业' }
  end

  test 'account_id should be generated automatically on creation' do
    employee = Employee.new @attrs
    employee.save
    assert_equal employees(:two).account_id + 1, employee.account_id

    Employee.delete_all
    (Employee::MIN_ID..Employee::MAX_ID).each do
      employee = Employee.new @attrs
      employee.save
    end
    employee = Employee.first
    old_id = employee.account_id
    employee.destroy
    employee = Employee.new @attrs
    employee.save
    assert_equal old_id, employee.account_id
  end

  test 'account_id should not exceed maximum id' do
    Employee.delete_all
    (Employee::MIN_ID..Employee::MAX_ID).each do
      employee = Employee.new @attrs
      employee.save
      assert_not_includes employee.errors[:account_id], "帐户达到最大值:#{Employee::MAX_ID}"
    end
    employee = Employee.new @attrs
    employee.save
    assert_includes employee.errors[:account_id], "帐户达到最大值:#{Employee::MAX_ID}"
  end

  test 'account_id should not change on update' do
    employee = employees(:one)
    old_id = employee.account_id
    employee.account_id += 1
    employee.save
    assert_equal old_id, employee.account_id
  end

  test 'name should be present' do
    employee = Employee.new
    assert employee.invalid?
  end
end
