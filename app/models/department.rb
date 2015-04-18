class Department < ActiveRecord::Base
  MIN_ID = 1
  MAX_ID = Rails.env == 'test' ? 10000 : 1000

  has_many :employees

  validates :name, presence: { message: '请输入名称'}

  include SerialNumber
  has_serial_number
end
