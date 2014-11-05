class User < ActiveRecord::Base
  include Account

  MIN_ID = 1
  MAX_ID = Rails.env == 'test' ? 10 : 9999

  has_secure_password
  has_unique_account_id

  validates :name, presence: true
  validates :permission, presence: true, inclusion: { in: 0..3 }
  validates_each :permission, on: :create do |record, attr, value|
    if value == 0 and record.class.where(attr => 0).count > 0
      record.errors.add(attr, '只能有一个超级用户')
    end
  end
  validates_each :permission, on: :update do |record, attr, value|
    unless record.class.find(record.id).send(attr) <= value
      record.errors.add(attr, '不能提升权限')
    end
  end
end
