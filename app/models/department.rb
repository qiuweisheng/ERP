class Department < ActiveRecord::Base
  has_many :employees

  validates :name, presence: true

  MIN_ID = 30001
  MAX_ID = Rails.env == 'test' ? 30010 : 39999

  include SerialNumber
  has_serial_number
end
