class Product < ActiveRecord::Base
  MIN_ID = 40001
  MAX_ID = Rails.env == 'test' ? 40010 : 49999
  
  include State
  include SerialNumber
  has_serial_number
  
  has_many :records

  validates :name, presence: { message: '名称必须填写'}
end
