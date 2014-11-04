class Client < ActiveRecord::Base
  include Account

  MIN_ID = 20001
  MAX_ID = Rails.env == 'test' ? 20099 : 29999

  auto_generate_account_id

  validates :name, presence: true
end
