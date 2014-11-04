class Employee < ActiveRecord::Base
  include Account

  MIN_ID = 10001
  MAX_ID = Rails.env == 'test' ? 10010 : 19999

  auto_generate_account_id

  validates :name, presence: true
end
