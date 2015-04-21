class Contractor < ActiveRecord::Base
  MIN_ID = 201
  MAX_ID = Rails.env == 'test' ? 10000 : 1000

  include State
  include SerialNumber
  has_serial_number
  
  has_many :transactions, as: :participant, class_name: 'Record'

  validates :name, presence: { message: '请输入名称'}
end
