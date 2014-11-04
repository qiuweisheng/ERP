class User < ActiveRecord::Base
  include Account

  MIN_ID = 1
  MAX_ID = Rails.env == 'test' ? 10 : 9999
  TYPE_TEXT = %w[超级用户 管理用户 收发部 柜台]
  TYPE = %w[super admin level_1 level_2]

  auto_generate_account_id
  has_secure_password

  validates :name, presence: true
  validates :account_type, presence: true, inclusion: { in: TYPE }
  validates_each :account_type do |record|
    if record.class.where(account_type: 'super').count > 0
      record.errors.add(:account_type, '只能有一个超级用户')
    end
  end
end
