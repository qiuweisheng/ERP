class Product < ActiveRecord::Base
  validates :name, presence: true

  MIN_ID = 40000
  MAX_ID = Rails.env == 'test' ? 40010 : 49999

  include SerialNumber
  has_serial_number
end
