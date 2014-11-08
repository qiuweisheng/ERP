require 'test_helper'

class ClientTest < ActiveSupport::TestCase
  setup do
    @attrs = { name: '王大锤' }
  end

  test 'serial_number should be generated automatically on creation' do
    client = Client.new @attrs
    client.save
    assert_equal clients(:two).serial_number + 1, client.serial_number

    Client.delete_all
    (Client::MIN_ID..Client::MAX_ID).each do
      client = Client.new @attrs
      client.save
    end
    client = Client.first
    old_id = client.serial_number
    client.destroy
    client = Client.new @attrs
    client.save
    assert_equal old_id, client.serial_number
  end

  test 'serial_number should not exceed maximum id' do
    Client.delete_all
    (Client::MIN_ID..Client::MAX_ID).each do
      client = Client.new @attrs
      client.save
    end
    client = Client.new @attrs
    assert client.invalid?
    assert_includes client.errors[:serial_number], "帐户达到最大值:#{Client::MAX_ID}"
  end

  test 'serial_number should not change on update' do
    client = clients(:one)
    old_id = client.serial_number
    client.serial_number += 1
    client.save
    assert_equal old_id, client.serial_number
  end

  test 'name should be present' do
    client = Client.new
    assert client.invalid?
  end
end
