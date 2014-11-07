class Employee < ActiveRecord::Base
  has_many :transactions, as: :client, class_name: 'Record'

  validates :name, presence: true

  MIN_ID = 10001
  MAX_ID = Rails.env == 'test' ? 10010 : 19999

  include Account
  has_unique_account_id
end
