class Client < ActiveRecord::Base
  MIN_ID = 81
  MAX_ID = 150 #Rails.env == 'test' ? 10000 : 1000

  include State
  include SerialNumber
  has_serial_number
  
  has_many :transactions, as: :participant, class_name: 'Record'
  has_many :records

  validates :name, presence: { message: '请输入名称'}
end
