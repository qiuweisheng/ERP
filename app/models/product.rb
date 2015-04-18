class Product < ActiveRecord::Base
  MIN_ID = 1
  MAX_ID = Rails.env == 'test' ? 100000 : 10000
  
  include State
  include SerialNumber
  has_serial_number
  
  has_many :records

  validates :name, presence: { message: '请输入名称'}
end
