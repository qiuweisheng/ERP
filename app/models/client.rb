class Client < ActiveRecord::Base
  has_many :transactions, as: :client, class_name: 'Record'

  validates :name, presence: true

  MIN_ID = 20001
  MAX_ID = Rails.env == 'test' ? 20099 : 29999

  include Account
  has_unique_account_id
end
