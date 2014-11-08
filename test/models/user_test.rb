require 'test_helper'

class UserTest < ActiveSupport::TestCase
  setup do
    @attrs = {
        name: '经理',
        password: 'secret',
        permission: 1
    }
  end

  test 'serial_number should be generated automatically on creation' do
    user = User.new @attrs
    user.save
    assert_equal users(:level_3).serial_number + 1, user.serial_number

    User.delete_all
    (User::MIN_ID..User::MAX_ID).each do
      user = User.new @attrs
      user.save
    end
    user = User.first
    old_id = user.serial_number
    user.destroy
    user = User.new @attrs
    user.save
    assert_equal old_id, user.serial_number
  end

  test 'serial_number should not exceed maximum id' do
    User.delete_all
    (User::MIN_ID..User::MAX_ID).each do
      user = User.new @attrs
      user.save
    end
    user = User.new @attrs
    assert user.invalid?
    assert_includes user.errors[:serial_number], "帐户达到最大值:#{User::MAX_ID}"
  end

  test 'serial_number should not change on update' do
    user = users(:super)
    old_id = user.serial_number
    user.serial_number += 1
    user.save
    assert_equal old_id, user.serial_number
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

  test 'permission should be present' do
    user = User.new @attrs
    user.permission = nil
    assert user.invalid?
  end

  test 'permission should be in range 0..3' do
    user = User.new @attrs
    assert user.valid?
    user.permission = 4
    assert user.invalid?
  end

  test 'should only have one super user' do
    attrs = {
        name: '大老板',
        password: 'secret',
        permission: 0
    }
    User.delete_all
    User.new(attrs).save
    user = User.new(attrs)
    assert user.invalid?
  end

  test 'should not prompt permission' do
    user = users(:admin)
    user.permission = 0
    assert user.invalid?
  end
end
