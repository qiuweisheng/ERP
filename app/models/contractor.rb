class Contractor < ActiveRecord::Base
  MIN_ID = 50001
  MAX_ID = Rails.env == 'test' ? 50099 : 59999

  has_many :transactions, as: :participant, class_name: 'Record'

  validates :name, presence: { message: '名称必须填写'}

  include SerialNumber
  has_serial_number
end
