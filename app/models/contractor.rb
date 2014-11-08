class Contractor < ActiveRecord::Base
  has_many :transactions, as: :participant, class_name: 'Record'

  validates :name, presence: true

  MIN_ID = 50001
  MAX_ID = Rails.env == 'test' ? 50099 : 59999

  include SerialNumber
  has_serial_number
end
