require 'test_helper'

class ClientTest < ActiveSupport::TestCase
  setup do
    @attrs = { name: '王大锤' }
  end

  test 'account_id should be generated automatically on creation' do
    client = Client.new @attrs
    client.save
    assert_equal clients(:two).account_id + 1, client.account_id

    client = clients(:two)
    old_id = client.account_id
    client = Client.new @attrs
    client.save
    assert old_id, client.account_id
  end

  test 'account_id should not exceed maximum id' do
    Client.delete_all
    (Client::MIN_ID..Client::MAX_ID).each do
      client = Client.new @attrs
      client.save
      assert_not_includes client.errors[:account_id], "帐户达到最大值:#{Client::MAX_ID}"
    end
    client = Client.new @attrs
    client.save
    assert_includes client.errors[:account_id], "帐户达到最大值:#{Client::MAX_ID}"
  end

  test 'account_id should not change on update' do
    client = clients(:one)
    old_id = client.account_id
    client.account_id += 1
    client.save
    assert_equal old_id, client.account_id
  end

  test 'name should be present' do
    client = Client.new
    assert client.invalid?
  end
end
