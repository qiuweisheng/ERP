class Client < ActiveRecord::Base
  include Account

  MIN_ID = 20001
  MAX_ID = Rails.env == 'test' ? 20099 : 29999

  validates :name, presence: true

  before_create :set_account_id
  before_update :reset_account_id
end
