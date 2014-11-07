require 'test_helper'

class RecordTest < ActiveSupport::TestCase
  setup do
    @attrs = {
        record_type: 0,
        origin_id: 0,
        product_id: 0,
        weight: 0.0,
        count: 0,
        user_id: 0,
        client_id: 0,
        client_type: 'User'
    }
  end

  test 'record_type should be present' do
    record = Record.new @attrs
    record.record_type = nil
    assert record.invalid?
  end

  test 'origin_id should be present' do
    record = Record.new @attrs
    record.origin_id = nil
    assert record.invalid?
  end

  test 'product_id should be present' do
    record = Record.new @attrs
    record.product_id = nil
    assert record.invalid?
  end

  test 'weight should be present' do
    record = Record.new @attrs
    record.weight = nil
    assert record.invalid?
  end

  test 'weight should be greater than or equal to 0.0' do
    record = Record.new @attrs
    record.weight = -1
    assert record.invalid?
  end

  test 'count should be present' do
    record = Record.new @attrs
    record.count = nil
    assert record.invalid?
  end

  test 'count should be greater than or equal to 0.0' do
    record = Record.new @attrs
    record.count = -1
    assert record.invalid?
  end

  test 'user_id should be present' do
    record = Record.new @attrs
    record.user_id = nil
    assert record.invalid?
  end

  test 'client_id should be present' do
    record = Record.new @attrs
    record.client_id = nil
    assert record.invalid?
  end

  test 'client_type should be present' do
    record = Record.new @attrs
    record.client_type = nil
    assert record.invalid?
  end
end
