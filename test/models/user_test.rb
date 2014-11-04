require 'test_helper'

class UserTest < ActiveSupport::TestCase
  setup do
    @attrs = {
        name: '柜台3',
        password: 'secret'
    }
  end

  test 'account_id should be generated automatically on creation' do
    user = User.new @attrs
    user.save
    assert_equal users(:two).account_id + 1, user.account_id

    user = users(:two)
    old_id = user.account_id
    user = User.new @attrs
    user.save
    assert old_id, user.account_id
  end

  test 'account_id should not exceed maximum id' do
    User.delete_all
    (User::MIN_ID..User::MAX_ID).each do
      user = User.new @attrs
      user.save
      assert_not_includes user.errors[:account_id], "帐户达到最大值:#{User::MAX_ID}"
    end
    user = User.new @attrs
    user.save
    assert_includes user.errors[:account_id], "帐户达到最大值:#{User::MAX_ID}"
  end

  test 'account_id should not change on update' do
    user = users(:one)
    old_id = user.account_id
    user.account_id += 1
    user.save
    assert_equal old_id, user.account_id
  end

  test 'name should be present' do
    user = Client.new
    assert user.invalid?
  end
end
