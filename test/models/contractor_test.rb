require 'test_helper'

class ContractorTest < ActiveSupport::TestCase
  setup do
    @attrs = { name: '王大锤' }
  end

  test 'serial_number should be generated automatically on creation' do
    contractor = Contractor.new @attrs
    contractor.save
    assert_equal contractors(:two).serial_number + 1, contractor.serial_number

    Contractor.delete_all
    (Contractor::MIN_ID..Contractor::MAX_ID).each do
      contractor = Contractor.new @attrs
      contractor.save
    end
    contractor = Contractor.first
    old_id = contractor.serial_number
    contractor.destroy
    contractor = Contractor.new @attrs
    contractor.save
    assert_equal old_id, contractor.serial_number
  end

  test 'serial_number should not exceed maximum id' do
    Contractor.delete_all
    (Contractor::MIN_ID..Contractor::MAX_ID).each do
      contractor = Contractor.new @attrs
      contractor.save
    end
    contractor = Contractor.new @attrs
    assert contractor.invalid?
    assert_includes contractor.errors[:serial_number], "帐户达到最大值:#{Contractor::MAX_ID}"
  end

  test 'serial_number should not change on update' do
    contractor = contractors(:one)
    old_id = contractor.serial_number
    contractor.serial_number += 1
    contractor.save
    assert_equal old_id, contractor.serial_number
  end

  test 'name should be present' do
    contractor = Contractor.new
    assert contractor.invalid?
  end
end
