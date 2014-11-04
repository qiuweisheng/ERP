require 'test_helper'

class UserTest < ActiveSupport::TestCase
  setup do
    @attrs = {
        name: '柜台3',
        password: 'secret',
        account_type: 'admin'
    }
  end

  test 'account_id should be generated automatically on creation' do
    user = User.new @attrs
    user.save
    assert_equal users(:two).account_id + 1, user.account_id

    User.delete_all
    (User::MIN_ID..User::MAX_ID).each do
      user = User.new @attrs
      user.save
    end
    user = User.first
    old_id = user.account_id
    user.destroy
    user = User.new @attrs
    user.save
    assert_equal old_id, user.account_id
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
    user = User.new @attrs
    user.name = nil
    assert user.invalid?
  end

  test 'password should include confirmation' do
    user = User.new @attrs
    user.password_confirmation = ''
    assert user.invalid?
  end

  test 'account_type should be present' do
    user = User.new @attrs
    user.account_type = nil
    assert user.invalid?
  end

  test "account_type should be in #{User::TYPE}" do
    user = User.new @attrs
    assert user.valid?
    user.account_type = 'user'
    assert user.invalid?
  end

  test 'should only have one super user' do
    attrs = {
        name: '大老板',
        password: 'secret',
        account_type: 'super'
    }
    User.delete_all
    User.new(attrs).save
    user = User.new(attrs)
    assert user.invalid?
  end
end
