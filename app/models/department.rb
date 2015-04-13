class Department < ActiveRecord::Base
  MIN_ID = 1
  MAX_ID = Rails.env == 'test' ? 10000 : 1000

  has_many :employees

  validates :name, presence: { message: '名称必须填写'}

  include SerialNumber
  has_serial_number
end
