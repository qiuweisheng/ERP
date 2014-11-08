class Client < ActiveRecord::Base
  has_many :transactions, as: :participant, class_name: 'Record'
  has_many :records

  validates :name, presence: true

  MIN_ID = 20001
  MAX_ID = Rails.env == 'test' ? 20099 : 29999

  include SerialNumber
  has_serial_number
end
