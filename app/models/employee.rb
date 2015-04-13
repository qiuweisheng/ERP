class Employee < ActiveRecord::Base
  MIN_ID = 31
  MAX_ID = Rails.env == 'test' ? 10000 : 1000
  
  include State
  include SerialNumber
  has_serial_number

  has_many :transactions, as: :participant, class_name: 'Record'
  has_many :records
  belongs_to :department

  validates :name, presence: { message: '名称必须填写'}
  validates :department_id, presence: { message: '部门必须填写'}
  validates :colleague_number, presence: { message: '人数必须填写' }
  validates :colleague_number, numericality: { greater_than: 0, message: '人数必须大于 0' }
end
