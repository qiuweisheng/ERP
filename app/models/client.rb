class Client < ActiveRecord::Base
  MIN_ID = 20001
  MAX_ID = Rails.env == 'test' ? 20099 : 29999

  has_many :transactions, as: :participant, class_name: 'Record'
  has_many :records

  validates :name, presence: { message: '名称必须填写'}

  include SerialNumber
  has_serial_number
end
