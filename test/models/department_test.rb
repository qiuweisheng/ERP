require 'test_helper'

class DepartmentTest < ActiveSupport::TestCase
  setup do
    @attrs = { name: '车花' }
  end

  test 'serial_number should be generated automatically on creation' do
    department = Department.new @attrs
    department.save
    assert_equal departments(:two).serial_number + 1, department.serial_number

    Department.delete_all
    (Department::MIN_ID..Department::MAX_ID).each do
      department = Department.new @attrs
      department.save
    end
    department = Department.first
    old_id = department.serial_number
    department.destroy
    department = Department.new @attrs
    department.save
    assert_equal old_id, department.serial_number
  end

  test 'serial_number should not exceed maximum id' do
    Department.delete_all
    (Department::MIN_ID..Department::MAX_ID).each do
      department = Department.new @attrs
      department.save
    end
    department = Department.new @attrs
    assert department.invalid?
    assert_includes department.errors[:serial_number], "帐户达到最大值:#{Department::MAX_ID}"
  end

  test 'serial_number should not change on update' do
    department = departments(:one)
    old_id = department.serial_number
    department.serial_number += 1
    department.save
    assert_equal old_id, department.serial_number
  end

  test 'name should be present' do
    department = Department.new
    assert department.invalid?
  end
end
