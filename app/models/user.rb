class User < ActiveRecord::Base
  include Account

  MIN_ID = 1
  MAX_ID = Rails.env == 'test' ? 99 : 9999

  has_secure_password

  #validates :name, presence: true

  before_create :set_account_id
  before_update :reset_account_id
end
