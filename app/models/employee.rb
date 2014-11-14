class Employee < ActiveRecord::Base
  MIN_ID = 10001
  MAX_ID = Rails.env == 'test' ? 10010 : 19999

  has_many :transactions, as: :participant, class_name: 'Record'
  has_many :records
  belongs_to :department

  validates :name, presence: { message: '名称必须填写'}
  validates :department_id, presence: { message: '部门必须填写'}

  include SerialNumber
  has_serial_number
end
