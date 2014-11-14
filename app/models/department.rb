class Department < ActiveRecord::Base
  MIN_ID = 30001
  MAX_ID = Rails.env == 'test' ? 30010 : 39999

  has_many :employees

  validates :name, presence: { message: '名称必须填写'}

  include SerialNumber
  has_serial_number
end
