class Employee < ActiveRecord::Base
  include Account

  MIN_ID = 10001
  MAX_ID = Rails.env == 'test' ? 10010 : 19999

  validates :name, presence: true

  before_create :set_account_id
  before_update :reset_account_id
end
